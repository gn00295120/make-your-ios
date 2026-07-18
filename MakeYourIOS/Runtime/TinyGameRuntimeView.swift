import SwiftUI
import UIKit

// swiftlint:disable file_length
// swiftlint:disable:next type_body_length
struct TinyGameRuntimeView: View {
    let title: String
    let program: TinyGameCompiledProgram
    let palette: GamePalette
    let hapticsEnabled: Bool

    @State private var engine: TinyGameEngine
    @State private var previousFrame: Date?
    @State private var accumulator = 0.0
    @State private var selectedDirections: [String: String] = [:]
    @Environment(\.runtimeDesign) private var design

    init(
        title: String = "Tiny game",
        program: TinyGameCompiledProgram,
        palette: GamePalette = .neon,
        hapticsEnabled: Bool = true
    ) {
        self.title = title
        self.program = program
        self.palette = palette
        self.hapticsEnabled = hapticsEnabled
        _engine = State(initialValue: TinyGameEngine(program: program))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            hud
            board
            transport
            controls
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: engine.phase) { _, phase in
            announceTerminalPhase(phase)
        }
    }

    private var header: some View {
        HStack {
            Label(title, systemImage: "gamecontroller.fill")
                .font(.headline)
                .lineLimit(1)
            Spacer()
            Text("Tick \(engine.tick)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var hud: some View {
        if !program.source.hud.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(program.source.hud) { item in
                        Label {
                            Text("\(item.label) \(engine.variables[item.variableID] ?? 0)")
                                .monospacedDigit()
                        } icon: {
                            Image(systemName: item.symbol)
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 8)
                        .background(.thinMaterial, in: Capsule())
                        .accessibilityIdentifier("tiny-game.hud.\(item.id)")
                    }
                }
            }
        }
    }

    private var board: some View {
        TimelineView(.animation(
            minimumInterval: tickInterval,
            paused: engine.phase != .playing
        )) { timeline in
            TinyGameCanvas(
                snapshot: engine.snapshot,
                world: program.source.world,
                colors: TinyGameColors(palette: palette, design: design)
            )
            .onChange(of: timeline.date) { _, date in advance(to: date) }
        }
        .overlay { phaseOverlay }
        .aspectRatio(
            Double(program.source.world.width) / Double(program.source.world.height),
            contentMode: .fit
        )
        .frame(maxWidth: .infinity, minHeight: 220)
        .clipShape(RoundedRectangle(cornerRadius: design.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: design.cornerRadius, style: .continuous)
                .stroke(
                    design.borderColor.opacity(max(design.borderOpacity, 0.16)),
                    lineWidth: max(1, design.borderWidth)
                )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) game board")
        .accessibilityValue(boardAccessibilityValue)
        .accessibilityIdentifier("tiny-game.board")
    }

    @ViewBuilder
    private var controls: some View {
        if !program.source.controls.isEmpty {
            VStack(spacing: 12) {
                ForEach(program.source.controls) { control in
                    controlView(control)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    // swiftlint:disable function_body_length
    private func controlView(_ control: TinyGameControlSpec) -> some View {
        switch control.kind {
        case .fourWay:
            VStack(spacing: 6) {
                TinyGameControlButton(
                    symbol: "chevron.up",
                    label: "\(control.label) up",
                    identifier: "tiny-game.control.\(control.id).up",
                    isSelected: selectedDirection(control.id, is: "up")
                ) { setDirection(control, x: 0, y: -1) }
                HStack(spacing: 18) {
                    TinyGameControlButton(
                        symbol: "chevron.left",
                        label: "\(control.label) left",
                        identifier: "tiny-game.control.\(control.id).left",
                        isSelected: selectedDirection(control.id, is: "left")
                    ) { setDirection(control, x: -1, y: 0) }
                    TinyGameControlButton(
                        symbol: "stop.fill",
                        label: "Stop \(control.label.lowercased())",
                        identifier: "tiny-game.control.\(control.id).stop",
                        isSelected: selectedDirection(control.id, is: "stop")
                    ) { setDirection(control, x: 0, y: 0) }
                    TinyGameControlButton(
                        symbol: "chevron.right",
                        label: "\(control.label) right",
                        identifier: "tiny-game.control.\(control.id).right",
                        isSelected: selectedDirection(control.id, is: "right")
                    ) { setDirection(control, x: 1, y: 0) }
                }
                TinyGameControlButton(
                    symbol: "chevron.down",
                    label: "\(control.label) down",
                    identifier: "tiny-game.control.\(control.id).down",
                    isSelected: selectedDirection(control.id, is: "down")
                ) { setDirection(control, x: 0, y: 1) }
            }
            .disabled(engine.phase != .playing)
        case .horizontal:
            HStack(spacing: 18) {
                TinyGameControlButton(
                    symbol: "arrow.left",
                    label: "\(control.label) left",
                    identifier: "tiny-game.control.\(control.id).left",
                    isSelected: selectedDirection(control.id, is: "left")
                ) { setDirection(control, x: -1, y: 0) }
                TinyGameControlButton(
                    symbol: "stop.fill",
                    label: "Stop \(control.label.lowercased())",
                    identifier: "tiny-game.control.\(control.id).stop",
                    isSelected: selectedDirection(control.id, is: "stop")
                ) { setDirection(control, x: 0, y: 0) }
                TinyGameControlButton(
                    symbol: "arrow.right",
                    label: "\(control.label) right",
                    identifier: "tiny-game.control.\(control.id).right",
                    isSelected: selectedDirection(control.id, is: "right")
                ) { setDirection(control, x: 1, y: 0) }
            }
            .disabled(engine.phase != .playing)
        case .actionButton:
            Button {
                engine.activateControl(control.id)
                playFeedback()
            } label: {
                Label(control.label, systemImage: control.symbol)
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .disabled(engine.phase != .playing)
            .accessibilityIdentifier("tiny-game.control.\(control.id).action")
        }
    }
    // swiftlint:enable function_body_length

    private var transport: some View {
        HStack(spacing: 10) {
            Button {
                engine.togglePause()
                previousFrame = nil
                accumulator = 0
                playFeedback()
            } label: {
                Label(transportLabel, systemImage: transportSymbol)
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .disabled(engine.phase == .won || engine.phase == .lost)
            .accessibilityIdentifier("tiny-game.transport.primary")

            Button {
                engine.restart()
                previousFrame = nil
                accumulator = 0
                selectedDirections.removeAll()
            } label: {
                Label("Restart", systemImage: "arrow.counterclockwise")
                    .frame(minHeight: 48)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("tiny-game.transport.restart")
        }
    }

    @ViewBuilder
    private var phaseOverlay: some View {
        switch engine.phase {
        case .playing:
            EmptyView()
        case .ready:
            phasePill("Ready", symbol: "play.fill")
        case .paused:
            phasePill("Paused", symbol: "pause.fill")
        case .won:
            phasePill("You win", symbol: "trophy.fill")
        case .lost:
            phasePill("Game over", symbol: "xmark.circle.fill")
        }
    }

    private func phasePill(_ label: String, symbol: String) -> some View {
        Label(label, systemImage: symbol)
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.black.opacity(0.68), in: Capsule())
            .allowsHitTesting(false)
            .accessibilityIdentifier("tiny-game.phase")
    }

    private var tickInterval: TimeInterval {
        1.0 / Double(program.source.tickRate.rawValue)
    }

    private var transportLabel: String {
        switch engine.phase {
        case .ready: "Start"
        case .playing: "Pause"
        case .paused: "Resume"
        case .won, .lost: "Finished"
        }
    }

    private var transportSymbol: String {
        engine.phase == .playing ? "pause.fill" : "play.fill"
    }

    private var phaseLabel: String {
        switch engine.phase {
        case .ready: "ready"
        case .playing: "playing"
        case .paused: "paused"
        case .won: "won"
        case .lost: "lost"
        }
    }

    // Coordinate callbacks intentionally mirror the generated IR axes.
    // swiftlint:disable:next identifier_name
    private func setDirection(_ control: TinyGameControlSpec, x: Int, y: Int) {
        engine.setDirectionalInput(x: x, y: y, controlID: control.id)
        selectedDirections[control.id] = directionName(horizontal: x, vertical: y)
    }

    private func selectedDirection(_ controlID: String, is direction: String) -> Bool {
        selectedDirections[controlID] == direction
    }

    private func directionName(horizontal: Int, vertical: Int) -> String {
        switch (horizontal, vertical) {
        case (-1, 0): "left"
        case (1, 0): "right"
        case (0, -1): "up"
        case (0, 1): "down"
        default: "stop"
        }
    }

    private var boardAccessibilityValue: String {
        var values = [phaseLabel, "tick \(engine.tick)"]
        values.append(contentsOf: program.source.hud.map { item in
            "\(item.label) \(engine.variables[item.variableID] ?? 0)"
        })
        let collectibles = engine.entities.filter { $0.role == .collectible }.count
        let hazards = engine.entities.filter { $0.role == .hazard }.count
        values.append("\(collectibles) collectibles remaining")
        if hazards > 0 { values.append("\(hazards) hazards") }
        return values.joined(separator: ", ")
    }

    private func announceTerminalPhase(_ phase: TinyGamePhase) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        switch phase {
        case .won:
            UIAccessibility.post(notification: .announcement, argument: "You win")
        case .lost:
            UIAccessibility.post(notification: .announcement, argument: "Game over")
        case .ready, .playing, .paused:
            break
        }
    }

    private func advance(to date: Date) {
        guard engine.phase == .playing else { return }
        let elapsed = previousFrame.map { date.timeIntervalSince($0) } ?? tickInterval
        previousFrame = date
        accumulator += min(max(elapsed, 0), tickInterval * Double(TinyGameAuditLimits.maximumCatchUpTicks))
        var completedTicks = 0
        while accumulator >= tickInterval,
              completedTicks < TinyGameAuditLimits.maximumCatchUpTicks,
              engine.phase == .playing {
            engine.step()
            accumulator -= tickInterval
            completedTicks += 1
        }
        playFeedback()
    }

    private func playFeedback() {
        let feedbackEvents = engine.drainFeedback()
        guard hapticsEnabled else { return }
        for feedback in feedbackEvents {
            feedback.play()
        }
    }
}

private struct TinyGameCanvas: View {
    let snapshot: TinyGameSnapshot
    let world: TinyGameWorldSpec
    let colors: TinyGameColors

    var body: some View {
        Canvas { context, size in
            let scale = min(
                size.width / Double(world.width),
                size.height / Double(world.height)
            )
            let worldSize = CGSize(
                width: Double(world.width) * scale,
                height: Double(world.height) * scale
            )
            let origin = CGPoint(
                x: (size.width - worldSize.width) / 2,
                y: (size.height - worldSize.height) / 2
            )
            let background = CGRect(origin: origin, size: worldSize)
            context.fill(
                Path(roundedRect: background, cornerRadius: 18),
                with: .linearGradient(
                    Gradient(colors: [
                        colors.backgroundStart,
                        colors.backgroundEnd
                    ]),
                    startPoint: background.origin,
                    endPoint: CGPoint(x: background.maxX, y: background.maxY)
                )
            )

            for entity in snapshot.entities {
                let rect = CGRect(
                    x: origin.x + Double(entity.x - entity.width / 2) * scale,
                    y: origin.y + Double(entity.y - entity.height / 2) * scale,
                    width: Double(entity.width) * scale,
                    height: Double(entity.height) * scale
                )
                let color = color(for: entity.visual.colorRole)
                switch entity.visual.kind {
                case .rectangle:
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: min(rect.width, rect.height) * 0.22),
                        with: .color(color)
                    )
                case .circle:
                    context.fill(Path(ellipseIn: rect), with: .color(color))
                case .sfSymbol:
                    var symbol = context.resolve(Image(systemName: entity.visual.symbol))
                    symbol.shading = .color(color)
                    context.draw(symbol, in: rect)
                }
            }
        }
    }

    private func color(for role: TinyGameColorRole) -> Color {
        switch role {
        case .primary: colors.primary
        case .accent: colors.accent
        case .collectible: colors.collectible
        case .hazard: colors.hazard
        case .surface: colors.surface
        case .foreground: colors.foreground
        }
    }
}

private struct TinyGameColors {
    var backgroundStart: Color
    var backgroundEnd: Color
    var primary: Color
    var accent: Color
    var collectible: Color
    var hazard: Color
    var surface: Color
    var foreground: Color

    init(palette: GamePalette, design: RuntimeDesignContext) {
        primary = design.accent
        accent = design.highlight
        surface = design.surface.opacity(0.82)
        foreground = .white
        switch palette {
        case .forest:
            backgroundStart = Color(red: 0.04, green: 0.14, blue: 0.10)
            backgroundEnd = Color(red: 0.12, green: 0.27, blue: 0.17)
            collectible = .yellow
            hazard = .orange
        case .neon:
            backgroundStart = Color(red: 0.04, green: 0.03, blue: 0.13)
            backgroundEnd = Color(red: 0.13, green: 0.08, blue: 0.28)
            collectible = .pink
            hazard = .orange
        case .sky:
            backgroundStart = Color(red: 0.24, green: 0.58, blue: 0.88)
            backgroundEnd = Color(red: 0.54, green: 0.82, blue: 0.98)
            collectible = .yellow
            hazard = .red
        case .candy:
            backgroundStart = Color(red: 0.18, green: 0.04, blue: 0.23)
            backgroundEnd = Color(red: 0.38, green: 0.08, blue: 0.34)
            collectible = .yellow
            hazard = .orange
        }
    }
}

private struct TinyGameControlButton: View {
    let symbol: String
    let label: String
    let identifier: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.headline.bold())
                .frame(width: 50, height: 48)
        }
        .buttonStyle(.bordered)
        .contentShape(Rectangle())
        .accessibilityLabel(label)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Movement continues until another direction or Stop is selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }
}

private extension TinyGameFeedback {
    @MainActor
    func play() {
        switch self {
        case .none:
            break
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
