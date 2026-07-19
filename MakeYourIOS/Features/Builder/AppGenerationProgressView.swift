import Foundation
import SwiftUI

enum AppGenerationProgress: Int, CaseIterable, Hashable, Sendable {
    case preparing
    case generating
    case validating
    case repairing
    case ready

    static let visibleSteps: [Self] = [.preparing, .generating, .validating]

    var label: String {
        switch self {
        case .preparing: "Prepare"
        case .generating: "Compose"
        case .validating: "Verify"
        case .repairing: "Repair"
        case .ready: "Ready"
        }
    }

    var detail: String {
        switch self {
        case .preparing:
            "Preparing a private request from your prompt and current app."
        case .generating:
            "OpenAI is composing native pages, data, actions, and visual design."
        case .validating:
            "MakeYour is checking every component, action, and device capability."
        case .repairing:
            "OpenAI is correcting the candidate with MakeYour’s validation feedback."
        case .ready:
            "Your validated next version is ready for review."
        }
    }

    static func elapsedDescription(seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds.rounded(.down)))
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}

struct AppGenerationFailure: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case timedOut
        case offline
        case cancelled
        case provider
        case invalidOutput
        case unknown
    }

    var kind: Kind
    var title: String
    var message: String
    var recovery: String
    var canRetry: Bool

    private init(kind: Kind, title: String, message: String, recovery: String, canRetry: Bool) {
        self.kind = kind
        self.title = title
        self.message = message
        self.recovery = recovery
        self.canRetry = canRetry
    }

    init(error: Error) {
        if let urlError = error as? URLError {
            self = Self(urlError: urlError)
        } else if let generationError = error as? AppGenerationError {
            self = Self(generationError: generationError)
        } else {
            self = Self(
                kind: .unknown,
                title: "Couldn’t finish this build",
                message: error.localizedDescription + " Your prompt is still here.",
                recovery: "Retry the same request or return to edit it.",
                canRetry: true
            )
        }
    }

    private init(urlError: URLError) {
        switch urlError.code {
        case .timedOut:
            self = Self(
                kind: .timedOut,
                title: "This build needs another try",
                message: "The connection stopped before OpenAI finished. Your prompt is still here.",
                recovery: "Check your connection, then retry the same request.",
                canRetry: true
            )
        case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .dnsLookupFailed:
            self = Self(
                kind: .offline,
                title: "Connection interrupted",
                message: "MakeYour could not keep a connection to OpenAI. Your prompt is still here.",
                recovery: "Restore your internet connection, then retry.",
                canRetry: true
            )
        case .cancelled:
            self = Self(
                kind: .cancelled,
                title: "Generation cancelled",
                message: "No changes were applied, and your prompt is still here.",
                recovery: "You can edit the prompt or start again whenever you’re ready.",
                canRetry: true
            )
        default:
            self = Self(
                kind: .unknown,
                title: "Couldn’t finish this build",
                message: "The network request failed. Your prompt is still here.",
                recovery: urlError.localizedDescription,
                canRetry: true
            )
        }
    }

    private init(generationError: AppGenerationError) {
        let kind: Kind
        switch generationError {
        case .api:
            kind = .provider
        case .invalidResponse, .invalidDocumentEncoding, .missingOutput, .refused, .incomplete:
            kind = .invalidOutput
        }
        self = Self(
            kind: kind,
            title: kind == .provider ? "OpenAI couldn’t finish" : "The app document needs another pass",
            message: generationError.localizedDescription + " Your prompt is still here.",
            recovery: "Retry the request. If it repeats, simplify only the conflicting requirement.",
            canRetry: true
        )
    }
}

struct AppGenerationProgressView: View {
    let mode: GenerationMode
    let progress: AppGenerationProgress
    let repairPass: Int
    let startedAt: Date
    let promptPreview: String
    let failure: AppGenerationFailure?
    let onCancel: () -> Void
    let onRetry: () -> Void
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            MakeYourTheme.canvas.ignoresSafeArea()
            ambientBackground

            ScrollView {
                VStack(spacing: 22) {
                    Spacer(minLength: 40)
                    statusGlyph
                    statusCopy
                    if failure == nil {
                        progressSteps
                        elapsedTime
                    }
                    promptCard
                    actions
                    Spacer(minLength: 28)
                }
                .frame(maxWidth: 430)
                .padding(.horizontal, 22)
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("builder.generation-dialog")
    }

    private var ambientBackground: some View {
        GeometryReader { proxy in
            Circle()
                .fill(MakeYourTheme.brand.opacity(0.16))
                .frame(width: proxy.size.width * 1.15)
                .blur(radius: 60)
                .offset(x: proxy.size.width * 0.25, y: -proxy.size.height * 0.22)

            Circle()
                .fill(MakeYourTheme.brandSecondary.opacity(0.12))
                .frame(width: proxy.size.width * 0.9)
                .blur(radius: 70)
                .offset(x: -proxy.size.width * 0.32, y: proxy.size.height * 0.66)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var statusGlyph: some View {
        if let failure {
            Image(systemName: failure.kind == .offline ? "wifi.slash" : "arrow.clockwise")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.orange)
                .frame(width: 92, height: 92)
                .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 28))
                .accessibilityHidden(true)
        } else if progress == .ready {
            Image(systemName: "checkmark")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 92, height: 92)
                .background(.green, in: RoundedRectangle(cornerRadius: 28))
                .symbolEffect(.bounce, value: progress)
                .accessibilityHidden(true)
        } else if reduceMotion {
            generationGlyph(expanded: false)
        } else {
            PhaseAnimator([false, true]) { expanded in
                generationGlyph(expanded: expanded)
            } animation: { _ in
                .easeInOut(duration: 1.15)
            }
        }
    }

    private func generationGlyph(expanded: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(MakeYourTheme.brandGradient, lineWidth: 3)
                .frame(width: 104, height: 104)
                .scaleEffect(expanded ? 1.06 : 0.94)
                .opacity(expanded ? 0.42 : 0.9)

            Image(systemName: "wand.and.sparkles")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 88, height: 88)
                .background(MakeYourTheme.brandGradient, in: RoundedRectangle(cornerRadius: 28))
                .shadow(color: MakeYourTheme.brand.opacity(0.25), radius: 22, y: 12)
        }
        .accessibilityHidden(true)
    }

    private var statusCopy: some View {
        VStack(spacing: 9) {
            Text(failure?.title ?? title)
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text(failure?.message ?? progressDetail)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let failure {
                Label(failure.recovery, systemImage: "lightbulb.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
        .accessibilityIdentifier("builder.generation-status")
    }

    private var title: String {
        if progress == .repairing {
            return "Repairing revision \(max(1, repairPass))"
        }
        return switch mode {
        case .full: "Building your tiny app"
        case .designOnly: "Designing your next look"
        }
    }

    private var progressDetail: String {
        guard progress == .repairing else { return progress.detail }
        return "OpenAI is correcting revision \(max(1, repairPass)) with exact feedback from MakeYour’s validator."
    }

    private var progressSteps: some View {
        HStack(spacing: 8) {
            ForEach(AppGenerationProgress.visibleSteps, id: \.self) { step in
                VStack(spacing: 7) {
                    ZStack {
                        Circle()
                            .fill(step.rawValue <= progress.rawValue
                                ? MakeYourTheme.brand
                                : Color.secondary.opacity(0.16))
                            .frame(width: 30, height: 30)
                        if step.rawValue < progress.rawValue || progress == .ready {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        } else {
                            Text("\(step.rawValue + 1)")
                                .font(.caption.bold())
                                .foregroundStyle(step.rawValue == progress.rawValue ? .white : .secondary)
                        }
                    }
                    Text(step.label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(step.rawValue <= progress.rawValue ? .primary : .secondary)
                }
                .frame(maxWidth: .infinity)

                if step != AppGenerationProgress.visibleSteps.last {
                    Capsule()
                        .fill(step.rawValue < progress.rawValue
                            ? MakeYourTheme.brand
                            : Color.secondary.opacity(0.16))
                        .frame(height: 3)
                        .offset(y: -10)
                }
            }
        }
        .padding(.horizontal, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Generation step: \(progress.label)")
        .accessibilityIdentifier("builder.generation-phase")
    }

    private var elapsedTime: some View {
        TimelineView(.periodic(from: startedAt, by: 1)) { context in
            let elapsed = max(0, context.date.timeIntervalSince(startedAt))
            VStack(spacing: 5) {
                Text("Working for \(AppGenerationProgress.elapsedDescription(seconds: elapsed))")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(waitingHint(elapsed: elapsed))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityIdentifier("builder.generation-elapsed")
        }
    }

    private func waitingHint(elapsed: TimeInterval) -> String {
        if repairPass > 0 {
            return "Automatic repair pass \(repairPass) is running. MakeYour will continue until it validates."
        }
        if elapsed >= 120 {
            return "Still working normally — complex apps need more time to compose and verify."
        } else {
            return "Larger apps can take a few minutes. Keep MakeYour open."
        }
    }

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Your request", systemImage: "text.quote")
                .font(.caption.bold())
                .foregroundStyle(MakeYourTheme.brand)
            Text(promptPreview)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
            Label("The original prompt stays in Builder until a version is applied.", systemImage: "lock.fill")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .makeYourCard(padding: 15)
    }

    @ViewBuilder
    private var actions: some View {
        if let failure {
            if failure.canRetry {
                Button(action: onRetry) {
                    Label("Retry generation", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(MakeYourTheme.brand)
                .accessibilityIdentifier("builder.generation.retry")
            }

            Button("Back to prompt", action: onClose)
                .buttonStyle(.bordered)
                .accessibilityIdentifier("builder.generation.close")
        } else if progress != .ready {
            Button("Cancel generation", role: .cancel, action: onCancel)
                .buttonStyle(.bordered)
                .accessibilityIdentifier("builder.generation.cancel")
        }
    }
}
