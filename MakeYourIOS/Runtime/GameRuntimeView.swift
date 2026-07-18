import SwiftUI
import UIKit

// The two complete game surfaces share controls, persistence, palette, and Canvas renderers here.
// Keeping that boundary in one file makes state transitions auditable as a unit.
// swiftlint:disable file_length

struct GameRuntimeView: View {
    let projectID: UUID
    let node: ComponentNode
    let tint: AppTint

    private var spec: GameSpec {
        node.game ?? GameSpec(
            kind: .snake,
            difficulty: .standard,
            palette: .neon,
            targetScore: 10,
            levelSeed: 42,
            playerName: "Player",
            collectibleName: "Token",
            haptics: true,
            program: nil
        )
    }

    @ViewBuilder
    var body: some View {
        switch spec.kind {
        case .snake:
            SnakeRuntimeGame(projectID: projectID, node: node, spec: spec, tint: tint)
        case .platformer:
            PlatformerRuntimeGame(projectID: projectID, node: node, spec: spec, tint: tint)
        case .custom:
            if let program = spec.program,
               let compiled = try? TinyGameCompiler().compile(program) {
                TinyGameRuntimeView(
                    title: node.title.isEmpty ? "Tiny game" : node.title,
                    program: compiled,
                    palette: spec.palette,
                    hapticsEnabled: spec.haptics
                )
                .id(program)
            } else {
                ContentUnavailableView(
                    "Game unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This tiny game contains an invalid or unsupported rule set.")
                )
            }
        }
    }
}

private struct SnakeRuntimeGame: View {
    let projectID: UUID
    let node: ComponentNode
    let spec: GameSpec
    let tint: AppTint

    @Environment(\.runtimeDesign) private var design
    @State private var engine: SnakeEngine
    @State private var bestScore = 0
    @State private var lastPhase: GamePhase = .ready

    private let stateStore = ProjectRuntimeStateStore()

    private var variant: ComponentVariant {
        RendererCatalog.normalizedVariant(node.resolvedPresentation.variant, for: .game)
    }

    init(projectID: UUID, node: ComponentNode, spec: GameSpec, tint: AppTint) {
        self.projectID = projectID
        self.node = node
        self.spec = spec
        self.tint = tint
        _engine = State(initialValue: SnakeEngine(
            difficulty: spec.difficulty,
            targetScore: spec.targetScore,
            seed: spec.levelSeed
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: design.componentSpacing) {
            if variant == .immersive {
                GameRuntimeHeader(
                    node: node,
                    score: engine.score,
                    target: spec.targetScore,
                    bestScore: bestScore,
                    collectibleName: spec.collectibleName,
                    compact: true
                )
                .padding(.horizontal, controlHorizontalInset)
                snakeBoard
            } else {
                GameRuntimeHeader(
                    node: node,
                    score: engine.score,
                    target: spec.targetScore,
                    bestScore: bestScore,
                    collectibleName: spec.collectibleName,
                    compact: false
                )
                snakeBoard
            }

            snakeControls
            GameTransportControls(
                phase: engine.phase,
                onStartOrPause: toggleStartOrPause,
                onRestart: restart
            )
            .padding(.horizontal, controlHorizontalInset)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear(perform: loadBestScore)
    }

    private var snakeBoard: some View {
        TimelineView(.animation(
            minimumInterval: engine.tickInterval,
            paused: engine.phase != .playing
        )) { timeline in
            SnakeCanvas(
                engine: engine,
                colors: GameColors(spec.palette),
                variant: variant
            )
            .onChange(of: timeline.date) { _, _ in tick() }
        }
        .overlay { GamePhaseOverlay(phase: engine.phase, readyAtTop: true) }
        .clipShape(
            RoundedRectangle(
                cornerRadius: [.fullBleed, .immersive].contains(variant) ? 0 : design.cornerRadius,
                style: .continuous
            )
        )
        .overlay {
            if variant == .framed {
                RoundedRectangle(cornerRadius: design.cornerRadius, style: .continuous)
                    .stroke(design.accent, lineWidth: max(2, design.borderWidth))
            }
        }
    }

    private var snakeControls: some View {
        VStack(spacing: 7) {
            DirectionButton(
                symbol: "chevron.up",
                accessibilityLabel: "Move up",
                identifier: "game.direction.up"
            ) { engine.changeDirection(.north) }
            HStack(spacing: 28) {
                DirectionButton(
                    symbol: "chevron.left",
                    accessibilityLabel: "Move left",
                    identifier: "game.direction.left"
                ) { engine.changeDirection(.left) }
                DirectionButton(
                    symbol: "chevron.down",
                    accessibilityLabel: "Move down",
                    identifier: "game.direction.down"
                ) { engine.changeDirection(.down) }
                DirectionButton(
                    symbol: "chevron.right",
                    accessibilityLabel: "Move right",
                    identifier: "game.direction.right"
                ) { engine.changeDirection(.right) }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, controlHorizontalInset)
    }

    private var controlHorizontalInset: CGFloat {
        [.fullBleed, .immersive].contains(variant) ? 16 : 0
    }

    private func tick() {
        let previousScore = engine.score
        engine.step()
        if engine.score > previousScore { feedback(.light) }
        handlePhaseAndScore()
    }

    private func toggleStartOrPause() {
        engine.togglePause()
        lastPhase = engine.phase
    }

    private func restart() {
        engine.restart()
        lastPhase = .ready
    }

    private func handlePhaseAndScore() {
        if engine.score > bestScore {
            bestScore = engine.score
            saveBestScore()
        }
        if engine.phase != lastPhase {
            if engine.phase == .won { feedback(.success) }
            if engine.phase == .lost { feedback(.error) }
            lastPhase = engine.phase
        }
    }

    private func feedback(_ style: GameFeedbackStyle) {
        guard spec.haptics else { return }
        style.play()
    }

    private func loadBestScore() {
        bestScore = (try? stateStore.load(
            GameStoredScore.self,
            projectID: projectID,
            nodeID: node.id,
            namespace: "game-score"
        ))?.value ?? 0
    }

    private func saveBestScore() {
        try? stateStore.save(
            GameStoredScore(value: bestScore),
            projectID: projectID,
            nodeID: node.id,
            namespace: "game-score"
        )
    }
}

private struct PlatformerRuntimeGame: View {
    let projectID: UUID
    let node: ComponentNode
    let spec: GameSpec
    let tint: AppTint

    @Environment(\.runtimeDesign) private var design
    @State private var engine: PlatformerEngine
    @State private var horizontalInput = 0.0
    @State private var jumpRequested = false
    @State private var previousFrame: Date?
    @State private var bestScore = 0
    @State private var lastPhase: GamePhase = .ready

    private let stateStore = ProjectRuntimeStateStore()

    private var variant: ComponentVariant {
        RendererCatalog.normalizedVariant(node.resolvedPresentation.variant, for: .game)
    }

    init(projectID: UUID, node: ComponentNode, spec: GameSpec, tint: AppTint) {
        self.projectID = projectID
        self.node = node
        self.spec = spec
        self.tint = tint
        _engine = State(initialValue: PlatformerEngine(
            seed: spec.levelSeed,
            difficulty: spec.difficulty,
            targetScore: spec.targetScore
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: design.componentSpacing) {
            if variant == .immersive {
                GameRuntimeHeader(
                    node: node,
                    score: engine.score,
                    target: spec.targetScore,
                    bestScore: bestScore,
                    collectibleName: spec.collectibleName,
                    compact: true
                )
                .padding(.horizontal, controlHorizontalInset)
                platformBoard
            } else {
                GameRuntimeHeader(
                    node: node,
                    score: engine.score,
                    target: spec.targetScore,
                    bestScore: bestScore,
                    collectibleName: spec.collectibleName,
                    compact: false
                )
                platformBoard
            }

            platformControls
            GameTransportControls(
                phase: engine.phase,
                onStartOrPause: toggleStartOrPause,
                onRestart: restart
            )
            .padding(.horizontal, controlHorizontalInset)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear(perform: loadBestScore)
    }

    private var platformBoard: some View {
        TimelineView(.animation(
            minimumInterval: 1.0 / 60.0,
            paused: engine.phase != .playing
        )) { timeline in
            PlatformerCanvas(
                engine: engine,
                colors: GameColors(spec.palette),
                variant: variant
            )
            .onChange(of: timeline.date) { _, date in updateFrame(date) }
        }
        .overlay { GamePhaseOverlay(phase: engine.phase, readyAtTop: false) }
        .clipShape(
            RoundedRectangle(
                cornerRadius: [.fullBleed, .immersive].contains(variant) ? 0 : design.cornerRadius,
                style: .continuous
            )
        )
        .overlay {
            if variant == .framed {
                RoundedRectangle(cornerRadius: design.cornerRadius, style: .continuous)
                    .stroke(design.accent, lineWidth: max(2, design.borderWidth))
            }
        }
    }

    private var platformControls: some View {
        HStack(spacing: 12) {
            DirectionButton(
                symbol: "arrow.left",
                accessibilityLabel: "Move left",
                identifier: "game.direction.left"
            ) { horizontalInput = -1 }
            DirectionButton(
                symbol: "stop.fill",
                accessibilityLabel: "Stop moving",
                identifier: "game.direction.stop"
            ) { horizontalInput = 0 }
            DirectionButton(
                symbol: "arrow.right",
                accessibilityLabel: "Move right",
                identifier: "game.direction.right"
            ) { horizontalInput = 1 }
            Spacer()
            Button {
                jumpRequested = true
            } label: {
                Label("Jump", systemImage: "arrow.up.circle.fill")
                    .font(.headline)
                    .frame(minWidth: 84, minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(design.accent)
            .accessibilityIdentifier("game.action.jump")
        }
        .padding(.horizontal, controlHorizontalInset)
    }

    private var controlHorizontalInset: CGFloat {
        [.fullBleed, .immersive].contains(variant) ? 16 : 0
    }

    private func updateFrame(_ date: Date) {
        let delta = previousFrame.map { date.timeIntervalSince($0) } ?? 1.0 / 60.0
        previousFrame = date
        let previousScore = engine.score
        engine.update(
            deltaTime: delta,
            input: PlatformerInput(horizontal: horizontalInput, jump: jumpRequested)
        )
        jumpRequested = false
        if engine.score > previousScore { feedback(.light) }
        handlePhaseAndScore()
    }

    private func toggleStartOrPause() {
        engine.togglePause()
        if engine.phase == .paused {
            horizontalInput = 0
        }
        previousFrame = nil
        lastPhase = engine.phase
    }

    private func restart() {
        engine.restart()
        horizontalInput = 0
        jumpRequested = false
        previousFrame = nil
        lastPhase = .ready
    }

    private func handlePhaseAndScore() {
        if engine.score > bestScore {
            bestScore = engine.score
            saveBestScore()
        }
        if engine.phase != lastPhase {
            if engine.phase == .won { feedback(.success) }
            if engine.phase == .lost { feedback(.error) }
            lastPhase = engine.phase
        }
    }

    private func feedback(_ style: GameFeedbackStyle) {
        guard spec.haptics else { return }
        style.play()
    }

    private func loadBestScore() {
        bestScore = (try? stateStore.load(
            GameStoredScore.self,
            projectID: projectID,
            nodeID: node.id,
            namespace: "game-score"
        ))?.value ?? 0
    }

    private func saveBestScore() {
        try? stateStore.save(
            GameStoredScore(value: bestScore),
            projectID: projectID,
            nodeID: node.id,
            namespace: "game-score"
        )
    }
}

private struct SnakeCanvas: View {
    let engine: SnakeEngine
    let colors: GameColors
    let variant: ComponentVariant

    var body: some View {
        Canvas { context, size in
            let cell = min(
                size.width / Double(engine.columns),
                size.height / Double(engine.rows)
            )
            let boardSize = CGSize(
                width: cell * Double(engine.columns),
                height: cell * Double(engine.rows)
            )
            let origin = CGPoint(
                x: (size.width - boardSize.width) / 2,
                y: (size.height - boardSize.height) / 2
            )
            let boardRect = CGRect(origin: origin, size: boardSize)
            context.fill(Path(roundedRect: boardRect, cornerRadius: 16), with: .color(colors.background))

            for column in 1..<engine.columns {
                let xPosition = origin.x + Double(column) * cell
                var line = Path()
                line.move(to: CGPoint(x: xPosition, y: boardRect.minY))
                line.addLine(to: CGPoint(x: xPosition, y: boardRect.maxY))
                context.stroke(line, with: .color(colors.primary.opacity(0.07)), lineWidth: 0.5)
            }
            for row in 1..<engine.rows {
                let yPosition = origin.y + Double(row) * cell
                var line = Path()
                line.move(to: CGPoint(x: boardRect.minX, y: yPosition))
                line.addLine(to: CGPoint(x: boardRect.maxX, y: yPosition))
                context.stroke(line, with: .color(colors.primary.opacity(0.07)), lineWidth: 0.5)
            }

            for (index, segment) in engine.snake.enumerated() {
                let rect = CGRect(
                    x: origin.x + Double(segment.column) * cell + 1.5,
                    y: origin.y + Double(segment.row) * cell + 1.5,
                    width: cell - 3,
                    height: cell - 3
                )
                context.fill(
                    Path(roundedRect: rect, cornerRadius: index == 0 ? cell / 3 : cell / 4),
                    with: .color(index == 0 ? colors.accent : colors.primary)
                )
            }

            let foodRect = CGRect(
                x: origin.x + Double(engine.food.column) * cell + cell * 0.2,
                y: origin.y + Double(engine.food.row) * cell + cell * 0.2,
                width: cell * 0.6,
                height: cell * 0.6
            )
            context.fill(Path(ellipseIn: foodRect), with: .color(colors.collectible))
        }
        .aspectRatio(Double(engine.columns) / Double(engine.rows), contentMode: .fit)
        .frame(maxWidth: variant == .framed ? 252 : .infinity)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Snake board, score \(engine.score)")
        .accessibilityValue("Target \(engine.targetScore)")
        .accessibilityIdentifier("game.board.snake")
    }
}

private struct PlatformerCanvas: View {
    let engine: PlatformerEngine
    let colors: GameColors
    let variant: ComponentVariant

    var body: some View {
        Canvas { context, size in
            let scale = size.height / engine.worldHeight
            let visibleWidth = size.width / scale
            let cameraX = min(
                max(0, engine.player.originX - visibleWidth * 0.34),
                max(0, engine.worldWidth - visibleWidth)
            )
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(colors.background))

            for platform in engine.platforms {
                let rect = canvasRect(platform, cameraX: cameraX, scale: scale)
                guard rect.maxX >= 0, rect.minX <= size.width else { continue }
                context.fill(
                    Path(roundedRect: rect, cornerRadius: platform.id == 0 ? 0 : 5),
                    with: .color(platform.id == 0 ? colors.ground : colors.primary)
                )
            }

            for hazard in engine.hazards {
                let rect = canvasRect(hazard, cameraX: cameraX, scale: scale)
                guard rect.maxX >= 0, rect.minX <= size.width else { continue }
                var spike = Path()
                spike.move(to: CGPoint(x: rect.minX, y: rect.maxY))
                spike.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
                spike.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                spike.closeSubpath()
                context.fill(spike, with: .color(colors.hazard))
            }

            for token in engine.collectibles where !token.isCollected {
                let center = CGPoint(
                    x: (token.centerX - cameraX) * scale,
                    y: token.centerY * scale
                )
                let rect = CGRect(x: center.x - 9, y: center.y - 9, width: 18, height: 18)
                guard rect.maxX >= 0, rect.minX <= size.width else { continue }
                context.fill(Path(ellipseIn: rect), with: .color(colors.collectible))
            }

            let goalX = (engine.goalX - cameraX) * scale
            if (-20...size.width + 20).contains(goalX) {
                let pole = CGRect(x: goalX, y: 330 * scale, width: 5, height: 210 * scale)
                context.fill(Path(pole), with: .color(colors.accent))
                let flag = CGRect(x: goalX + 5, y: 340 * scale, width: 44, height: 30)
                context.fill(Path(flag), with: .color(colors.collectible))
            }

            let playerRect = canvasRect(engine.player, cameraX: cameraX, scale: scale)
            context.fill(
                Path(roundedRect: playerRect, cornerRadius: 8),
                with: .color(colors.accent)
            )
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .frame(maxWidth: .infinity, minHeight: variant == .immersive ? 300 : 210)
        .clipShape(
            RoundedRectangle(
                cornerRadius: [.fullBleed, .immersive].contains(variant) ? 0 : 16,
                style: .continuous
            )
        )
        .accessibilityLabel("Platform game, score \(engine.score)")
        .accessibilityValue("Target \(engine.targetScore)")
        .accessibilityIdentifier("game.board.platformer")
    }

    private func canvasRect(_ rect: PlatformRect, cameraX: Double, scale: Double) -> CGRect {
        CGRect(
            x: (rect.originX - cameraX) * scale,
            y: rect.originY * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )
    }
}

private struct GameRuntimeHeader: View {
    let node: ComponentNode
    let score: Int
    let target: Int
    let bestScore: Int
    let collectibleName: String
    let compact: Bool

    @Environment(\.runtimeDesign) private var design

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Label(
                    node.title.isEmpty ? "Tiny game" : node.title,
                    systemImage: node.symbol.isEmpty ? "gamecontroller.fill" : node.symbol
                )
                .font(design.sectionFont)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .accessibilityAddTraits(.isHeader)
                if !compact, !node.subtitle.isEmpty {
                    Text(node.subtitle)
                        .font(design.captionFont)
                        .foregroundStyle(design.secondaryForeground)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(score) / \(target)")
                    .font(design.titleFont.monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("Best \(bestScore) · \(collectibleName)")
                    .font(design.captionFont)
                    .foregroundStyle(design.secondaryForeground)
            }
        }
        .foregroundStyle(design.primaryForeground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(node.title), \(node.subtitle), score \(score) of \(target), best \(bestScore)"
        )
    }
}

private struct GamePhaseOverlay: View {
    let phase: GamePhase
    let readyAtTop: Bool

    @Environment(\.runtimeDesign) private var design

    @ViewBuilder
    var body: some View {
        switch phase {
        case .playing:
            EmptyView()
        case .ready:
            Label("Ready to play", systemImage: "play.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(.black.opacity(0.62), in: Capsule())
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: readyAtTop ? .top : .center
                )
                .padding(.top, readyAtTop ? 14 : 0)
                .allowsHitTesting(false)
                .accessibilityIdentifier("game.phase.status")
        case .paused, .won, .lost:
            ZStack {
                Color.black.opacity(0.46)
                VStack(spacing: 10) {
                    Image(systemName: phaseSymbol).font(.title.bold())
                    Text(phaseTitle).font(.headline)
                }
                .foregroundStyle(.white)
            }
            .clipShape(
                RoundedRectangle(cornerRadius: design.cornerRadius, style: .continuous)
            )
            .allowsHitTesting(false)
            .accessibilityIdentifier("game.phase.status")
        }
    }

    private var phaseTitle: String {
        switch phase {
        case .ready: "Ready?"
        case .playing: "Playing"
        case .paused: "Paused"
        case .won: "Goal reached!"
        case .lost: "Try again"
        }
    }

    private var phaseSymbol: String {
        switch phase {
        case .ready: "play.fill"
        case .playing: "gamecontroller.fill"
        case .paused: "pause.fill"
        case .won: "trophy.fill"
        case .lost: "arrow.counterclockwise"
        }
    }
}

private struct GameTransportControls: View {
    let phase: GamePhase
    let onStartOrPause: () -> Void
    let onRestart: () -> Void

    @Environment(\.runtimeDesign) private var design

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onStartOrPause) {
                Label(controlLabel, systemImage: controlSymbol)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(design.accent)
            .disabled(phase == .won || phase == .lost)
            .accessibilityIdentifier("game.transport.primary")

            Button(action: onRestart) {
                Label("Restart", systemImage: "arrow.counterclockwise")
                    .frame(minHeight: 48)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("game.transport.restart")
        }
    }

    private var controlLabel: String {
        switch phase {
        case .playing: "Pause"
        case .paused: "Resume"
        case .ready: "Start"
        case .won, .lost: "Finished"
        }
    }

    private var controlSymbol: String {
        phase == .playing ? "pause.fill" : "play.fill"
    }
}

private struct DirectionButton: View {
    let symbol: String
    let accessibilityLabel: String
    let identifier: String
    let action: () -> Void

    @Environment(\.runtimeDesign) private var design

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.headline.bold())
                .frame(width: 50, height: 46)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(
            design.controlShape == .pill
                ? .capsule
                : .roundedRectangle(radius: design.controlCornerRadius)
        )
        .tint(design.accent)
        .contentShape(Rectangle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(identifier)
    }
}

private struct GameStoredScore: Codable {
    var value: Int
}

private struct GameColors {
    var background: Color
    var primary: Color
    var accent: Color
    var collectible: Color
    var ground: Color
    var hazard: Color

    private init(
        background: Color,
        primary: Color,
        accent: Color,
        collectible: Color,
        ground: Color,
        hazard: Color
    ) {
        self.background = background
        self.primary = primary
        self.accent = accent
        self.collectible = collectible
        self.ground = ground
        self.hazard = hazard
    }

    init(_ palette: GamePalette) {
        switch palette {
        case .forest:
            self.init(
                background: Color(red: 0.06, green: 0.16, blue: 0.12),
                primary: .green,
                accent: .mint,
                collectible: .yellow,
                ground: Color(red: 0.22, green: 0.32, blue: 0.18),
                hazard: .orange
            )
        case .neon:
            self.init(
                background: Color(red: 0.04, green: 0.03, blue: 0.13),
                primary: .cyan,
                accent: .purple,
                collectible: .pink,
                ground: Color(red: 0.12, green: 0.10, blue: 0.28),
                hazard: .orange
            )
        case .sky:
            self.init(
                background: Color(red: 0.48, green: 0.80, blue: 0.98),
                primary: .white,
                accent: .indigo,
                collectible: .yellow,
                ground: Color(red: 0.23, green: 0.58, blue: 0.29),
                hazard: .red
            )
        case .candy:
            self.init(
                background: Color(red: 0.20, green: 0.06, blue: 0.22),
                primary: .pink,
                accent: .cyan,
                collectible: .yellow,
                ground: .purple,
                hazard: .orange
            )
        }
    }
}

private enum GameFeedbackStyle {
    case light
    case success
    case error

    @MainActor
    func play() {
        switch self {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
