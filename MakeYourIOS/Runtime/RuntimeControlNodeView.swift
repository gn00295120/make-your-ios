import SwiftUI

struct RuntimeControlNodeView: View {
    let node: ComponentNode
    @Bindable var session: RuntimeSessionState
    let onValueChanged: () -> Void

    @Environment(\.runtimeDesign) private var design

    private var spec: RuntimeControlSpec {
        node.control ?? RuntimeControlSpec(
            kind: .toggle,
            minimum: 0,
            maximum: 1,
            step: 1,
            unit: ""
        )
    }

    private var minimum: Double {
        spec.minimum.isFinite ? spec.minimum : 0
    }

    private var maximum: Double {
        spec.maximum.isFinite && spec.maximum > minimum ? spec.maximum : minimum + 1
    }

    private var step: Double {
        guard spec.step.isFinite, spec.step > 0 else { return 1 }
        return min(spec.step, maximum - minimum)
    }

    private var resolvedTitle: String {
        session.resolveTemplate(node.title)
    }

    private var resolvedSubtitle: String {
        session.resolveTemplate(node.subtitle)
    }

    private var resolvedValue: Double {
        let stored = session.binding(for: node.binding, fallback: node.value)
        return min(max(Double(stored) ?? minimum, minimum), maximum)
    }

    private var formattedValue: String {
        let number = resolvedValue.formatted(
            .number.precision(.fractionLength(0...6))
        )
        return spec.unit.isEmpty ? number : "\(number) \(spec.unit)"
    }

    private var numberBinding: Binding<Double> {
        Binding(
            get: { resolvedValue },
            set: { value in
                let bounded = min(max(value, minimum), maximum)
                session.set(storageString(bounded), for: node.binding)
                onValueChanged()
            }
        )
    }

    private var booleanBinding: Binding<Bool> {
        Binding(
            get: {
                session.binding(for: node.binding, fallback: node.value).lowercased() == "true"
            },
            set: { value in
                session.set(value ? "true" : "false", for: node.binding)
                onValueChanged()
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            switch spec.kind {
            case .toggle:
                Toggle(isOn: booleanBinding) {
                    controlLabel
                }
                .frame(minHeight: 44)
                .accessibilityValue(booleanBinding.wrappedValue ? "On" : "Off")
            case .slider:
                controlLabel
                HStack(spacing: 12) {
                    Slider(value: numberBinding, in: minimum...maximum, step: step)
                        .frame(minHeight: 44)
                    Text(formattedValue)
                        .font(design.captionFont.monospacedDigit().weight(.semibold))
                        .foregroundStyle(design.secondaryForeground)
                        .frame(minWidth: 58, alignment: .trailing)
                }
            case .stepper:
                Stepper(value: numberBinding, in: minimum...maximum, step: step) {
                    HStack {
                        controlLabel
                        Spacer(minLength: 8)
                        Text(formattedValue)
                            .font(design.bodyFont.monospacedDigit().weight(.semibold))
                    }
                }
                .frame(minHeight: 44)
            case .progress:
                controlLabel
                HStack(spacing: 12) {
                    ProgressView(value: normalizedProgress)
                        .frame(maxWidth: .infinity)
                    Text(formattedValue)
                        .font(design.captionFont.monospacedDigit().weight(.semibold))
                        .foregroundStyle(design.secondaryForeground)
                }
                .frame(minHeight: 44)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tint(design.accent)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(resolvedTitle)
        .accessibilityValue(formattedValue)
        .accessibilityIdentifier("runtime.node.\(node.id)")
    }

    private var controlLabel: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(resolvedTitle)
                .font(design.bodyFont.weight(.semibold))
            if !resolvedSubtitle.isEmpty {
                Text(resolvedSubtitle)
                    .font(design.captionFont)
                    .foregroundStyle(design.secondaryForeground)
            }
        }
    }

    private var normalizedProgress: Double {
        (resolvedValue - minimum) / (maximum - minimum)
    }

    private func storageString(_ value: Double) -> String {
        let formatted = String(
            format: "%.6f",
            locale: Locale(identifier: "en_US_POSIX"),
            value
        )
        return formatted
            .replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
    }
}
