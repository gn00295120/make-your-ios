// swiftlint:disable file_length
import PhotosUI
import SwiftUI
import UIKit

struct DesignStudioResult {
    var theme: AppVisualTheme
    var tint: AppTint
    var symbol: String
    var pagePresentation: PagePresentation
    var canvasBackgroundImageData: Data?
    var removesCanvasBackground: Bool
}

// swiftlint:disable:next type_body_length
struct DesignStudioSheet: View {
    let project: WorkspaceProject
    let onApply: (DesignStudioResult) throws -> Void
    let onUseAIPrompt: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(LocalAssetStore.self) private var assetStore
    @State private var draft: DesignStudioDraft
    @State private var undoStack: [DesignStudioDraft] = []
    @State private var redoStack: [DesignStudioDraft] = []
    @State private var selectedBackgroundItem: PhotosPickerItem?
    @State private var errorMessage: String?

    init(
        project: WorkspaceProject,
        onApply: @escaping (DesignStudioResult) throws -> Void,
        onUseAIPrompt: @escaping (String) -> Void
    ) {
        self.project = project
        self.onApply = onApply
        self.onUseAIPrompt = onUseAIPrompt
        let startPage = project.document.pages.first(where: {
            $0.id == project.document.startPageID
        }) ?? project.document.pages.first
        _draft = State(initialValue: DesignStudioDraft(
            theme: project.document.resolvedTheme,
            tint: project.document.tint,
            symbol: project.document.symbol,
            pagePresentation: startPage?.resolvedPresentation ?? .flow,
            backgroundChange: .unchanged
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    intro
                    DesignStudioDevicePreview(
                        projectName: project.document.name,
                        draft: draft,
                        backgroundImage: previewBackgroundImage
                    )
                    styleSection
                    colorSection
                    typeSection
                    layoutSection
                    shapeSection
                    motionSection
                    aiDesignAction
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .background(MakeYourTheme.canvas)
            .navigationTitle("Design Studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { studioToolbar }
            .safeAreaInset(edge: .bottom) { applyBar }
            .onChange(of: selectedBackgroundItem) { _, item in
                guard let item else { return }
                Task { await importBackground(item) }
            }
            .alert("Couldn’t update the design", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your app, your visual language")
                .font(.title2.bold())
            Text(
                "Edit locally, preview every choice, then apply everything as one new version. "
                    + "Cancel leaves the current app untouched."
            )
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var styleSection: some View {
        StudioSection(title: "Style", symbol: "paintpalette.fill") {
            presetPicker
            choicePicker(
                "Appearance",
                values: ThemeAppearance.allCases,
                selection: draftBinding(\.theme.appearance)
            )
            choicePicker(
                "Canvas",
                values: ThemeBackground.allCases,
                selection: draftBinding(\.theme.background)
            )
            choicePicker(
                "Default surface",
                values: ComponentSurface.allCases,
                selection: draftBinding(\.theme.defaultSurface)
            )
            tintPicker
            backgroundPhotoControls
            symbolPicker

            Button("Restore selected preset", systemImage: "arrow.counterclockwise") {
                restoreSelectedPreset()
            }
            .frame(minHeight: 44)
            .accessibilityHint("Resets design tokens but keeps the canvas photo")
        }
    }

    private var presetPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(VisualThemePreset.allCases) { preset in
                    Button {
                        applyPreset(preset)
                    } label: {
                        VStack(spacing: 7) {
                            Image(systemName: preset.symbol)
                                .font(.headline)
                            Text(preset.label)
                                .font(.caption.weight(.medium))
                        }
                        .frame(width: 74, height: 58)
                        .background(
                            preset == draft.theme.preset
                                ? draft.tint.color.opacity(0.18)
                                : Color.primary.opacity(0.05),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(preset == draft.theme.preset ? draft.tint.color : .primary)
                    .accessibilityLabel("Use \(preset.label) preset")
                    .accessibilityIdentifier("design.preset.\(preset.rawValue)")
                }
            }
        }
    }

    private var tintPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("App accent")
                .font(.subheadline.weight(.medium))
            HStack(spacing: 10) {
                ForEach(AppTint.allCases, id: \.self) { tint in
                    Button {
                        set(\.tint, to: tint)
                    } label: {
                        Circle()
                            .fill(tint.color)
                            .frame(width: 36, height: 36)
                            .overlay {
                                if tint == draft.tint {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Use \(tint.rawValue) app accent")
                    .accessibilityAddTraits(tint == draft.tint ? .isSelected : [])
                }
            }
        }
    }

    private var backgroundPhotoControls: some View {
        let backgroundPhotoSelected = hasBackgroundPhoto
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Canvas background photo")
                        .font(.subheadline.weight(.medium))
                    Text("The photo stays local; only its semantic slot is stored in the app document.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if backgroundPhotoSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .accessibilityLabel("Background photo selected")
                }
            }

            HStack {
                PhotosPicker(
                    selection: $selectedBackgroundItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label(
                        backgroundPhotoSelected ? "Replace photo" : "Choose photo",
                        systemImage: "photo"
                    )
                        .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)

                if backgroundPhotoSelected {
                    Button("Clear", role: .destructive) {
                        mutate { value in
                            value.theme.backgroundAssetBinding = nil
                            value.backgroundChange = .removed
                        }
                    }
                    .frame(minHeight: 44)
                }
            }
        }
    }

    private var symbolPicker: some View {
        DisclosureGroup {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 48))], spacing: 8) {
                ForEach(GeneratedAppPayload.allowedSymbols.sorted(), id: \.self) { symbol in
                    Button {
                        set(\.symbol, to: symbol)
                    } label: {
                        Image(systemName: symbol)
                            .font(.headline)
                            .frame(width: 48, height: 48)
                            .background(
                                symbol == draft.symbol
                                    ? draft.tint.color.opacity(0.18)
                                    : Color.primary.opacity(0.05),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(symbol == draft.symbol ? draft.tint.color : .primary)
                    .accessibilityLabel("Use \(symbol) app icon")
                    .accessibilityAddTraits(symbol == draft.symbol ? .isSelected : [])
                }
            }
            .padding(.top, 8)
        } label: {
            Label("App icon symbol", systemImage: draft.symbol)
                .font(.subheadline.weight(.medium))
                .frame(minHeight: 44)
        }
    }

    private var colorSection: some View {
        StudioSection(title: "Colors", symbol: "swatchpalette.fill") {
            Text("Brand")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            paletteColorPicker("Primary", keyPath: \.primaryHex)
            paletteColorPicker("Secondary", keyPath: \.secondaryHex)
            paletteColorPicker("Accent", keyPath: \.accentHex)
            Divider()
            Text("Light appearance")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            paletteColorPicker("Canvas", keyPath: \.canvasLightHex)
            paletteColorPicker("Surface", keyPath: \.surfaceLightHex)
            Divider()
            Text("Dark appearance")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            paletteColorPicker("Canvas", keyPath: \.canvasDarkHex)
            paletteColorPicker("Surface", keyPath: \.surfaceDarkHex)
        }
    }

    private var typeSection: some View {
        StudioSection(title: "Type", symbol: "textformat") {
            choicePicker(
                "Font design",
                values: ThemeTypography.allCases,
                selection: draftBinding(\.theme.typography)
            )
            choicePicker(
                "Type scale",
                values: ThemeTypeScale.allCases,
                selection: typeScaleBinding
            )
            choicePicker(
                "Title weight",
                values: ThemeTitleWeight.allCases,
                selection: titleWeightBinding
            )
        }
    }

    private var layoutSection: some View {
        StudioSection(title: "Layout", symbol: "rectangle.3.group") {
            choicePicker(
                "Page layout",
                values: PageLayout.allCases,
                selection: draftBinding(\.pagePresentation.layout)
            )
            choicePicker(
                "Page navigation",
                values: PageNavigationStyle.allCases,
                selection: navigationBinding
            )
            choicePicker(
                "Density",
                values: ThemeDensity.allCases,
                selection: draftBinding(\.theme.density)
            )
            Toggle("Show navigation titles", isOn: draftBinding(\.pagePresentation.showsNavigationTitle))
                .frame(minHeight: 44)
        }
    }

    private var shapeSection: some View {
        StudioSection(title: "Shape & depth", symbol: "square.on.square") {
            choicePicker(
                "Corners",
                values: ThemeCornerStyle.allCases,
                selection: draftBinding(\.theme.cornerStyle)
            )
            choicePicker(
                "Controls",
                values: ThemeControlShape.allCases,
                selection: controlShapeBinding
            )
            choicePicker(
                "Elevation",
                values: ThemeElevation.allCases,
                selection: elevationBinding
            )
            choicePicker(
                "Borders",
                values: ThemeStroke.allCases,
                selection: strokeBinding
            )
        }
    }

    private var motionSection: some View {
        StudioSection(title: "Motion", symbol: "waveform.path.ecg") {
            choicePicker(
                "Motion language",
                values: ThemeMotion.allCases,
                selection: motionBinding
            )
            Text("Tiny apps honor Reduce Motion. Turning it on never disables Design Studio controls.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var aiDesignAction: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Continue with AI", systemImage: "sparkles")
                .font(.headline)
            Text("保留功能，只改設計 — the host will lock features, actions, data, and capabilities.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                onUseAIPrompt(designOnlyPrompt)
            } label: {
                Label("Prepare design-only AI prompt", systemImage: "wand.and.stars")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .tint(draft.tint.color)
            .accessibilityHint("Fills the Builder prompt without sending an API request")
        }
        .makeYourCard()
    }

    @ToolbarContentBuilder
    private var studioToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(undoStack.isEmpty)
            .accessibilityLabel("Undo design change")

            Button {
                redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(redoStack.isEmpty)
            .accessibilityLabel("Redo design change")
        }
    }

    private var applyBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                apply()
            } label: {
                Text("Apply as new version")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(draft.tint.color)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.bar)
            .accessibilityHint("Saves all draft design changes in one version")
        }
    }

    private var hasBackgroundPhoto: Bool {
        switch draft.backgroundChange {
        case .replacement:
            return true
        case .removed:
            return false
        case .unchanged:
            guard let binding = draft.theme.backgroundAssetBinding else { return false }
            return assetStore.hasImage(projectID: project.id, binding: binding)
        }
    }

    private var previewBackgroundImage: UIImage? {
        switch draft.backgroundChange {
        case .replacement(let data):
            return UIImage(data: data)
        case .removed:
            return nil
        case .unchanged:
            guard let binding = draft.theme.backgroundAssetBinding else { return nil }
            return assetStore.image(projectID: project.id, binding: binding)
        }
    }

    private var designOnlyPrompt: String {
        let palette = draft.theme.resolvedPalette
        return """
        Preserve every feature, action, data binding, capability, and piece of content. Change only the \
        visual design. Use a \(draft.theme.preset.label) direction with \(draft.theme.typography.rawValue) \
        typography, \(draft.theme.resolvedTypeScale.rawValue) type scale, \
        \(draft.theme.resolvedTitleWeight.rawValue) titles, \(draft.pagePresentation.layout.rawValue) layout, \
        \(draft.pagePresentation.resolvedNavigationStyle.rawValue) navigation, \
        \(draft.theme.resolvedControlShape.rawValue) controls, \(draft.theme.resolvedElevation.rawValue) depth, \
        and \(draft.theme.resolvedMotion.rawValue) motion. Use brand colors \(palette.primaryHex), \
        \(palette.secondaryHex), and \(palette.accentHex). Keep the result accessible in light and dark mode.
        """
    }

    private var typeScaleBinding: Binding<ThemeTypeScale> {
        resolvedThemeBinding(\.typeScale, resolved: \.resolvedTypeScale)
    }

    private var titleWeightBinding: Binding<ThemeTitleWeight> {
        resolvedThemeBinding(\.titleWeight, resolved: \.resolvedTitleWeight)
    }

    private var elevationBinding: Binding<ThemeElevation> {
        resolvedThemeBinding(\.elevation, resolved: \.resolvedElevation)
    }

    private var strokeBinding: Binding<ThemeStroke> {
        resolvedThemeBinding(\.stroke, resolved: \.resolvedStroke)
    }

    private var controlShapeBinding: Binding<ThemeControlShape> {
        resolvedThemeBinding(\.controlShape, resolved: \.resolvedControlShape)
    }

    private var motionBinding: Binding<ThemeMotion> {
        resolvedThemeBinding(\.motion, resolved: \.resolvedMotion)
    }

    private var navigationBinding: Binding<PageNavigationStyle> {
        Binding(
            get: { draft.pagePresentation.resolvedNavigationStyle },
            set: { value in
                mutate { $0.pagePresentation.navigationStyle = value }
            }
        )
    }

    private func choicePicker<Option>(
        _ title: String,
        values: [Option],
        selection: Binding<Option>
    ) -> some View where Option: Hashable & RawRepresentable, Option.RawValue == String {
        Picker(title, selection: selection) {
            ForEach(values, id: \.self) { value in
                Text(value.rawValue.studioLabel).tag(value)
            }
        }
        .frame(minHeight: 44)
    }

    private func paletteColorPicker(
        _ title: String,
        keyPath: WritableKeyPath<BrandPalette, String>
    ) -> some View {
        ColorPicker(title, selection: paletteBinding(keyPath), supportsOpacity: false)
            .frame(minHeight: 44)
            .accessibilityLabel("\(title) color")
    }

    private func paletteBinding(
        _ keyPath: WritableKeyPath<BrandPalette, String>
    ) -> Binding<Color> {
        Binding(
            get: { Color(studioHex: draft.theme.resolvedPalette[keyPath: keyPath]) },
            set: { color in
                mutate { value in
                    var palette = value.theme.resolvedPalette
                    palette[keyPath: keyPath] = color.studioHex
                    value.theme.palette = palette
                }
            }
        )
    }

    private func draftBinding<Value: Equatable>(
        _ keyPath: WritableKeyPath<DesignStudioDraft, Value>
    ) -> Binding<Value> {
        Binding(
            get: { draft[keyPath: keyPath] },
            set: { set(keyPath, to: $0) }
        )
    }

    private func resolvedThemeBinding<Value: Equatable>(
        _ writable: WritableKeyPath<AppVisualTheme, Value?>,
        resolved: KeyPath<AppVisualTheme, Value>
    ) -> Binding<Value> {
        Binding(
            get: { draft.theme[keyPath: resolved] },
            set: { newValue in
                mutate { $0.theme[keyPath: writable] = newValue }
            }
        )
    }

    private func set<Value: Equatable>(
        _ keyPath: WritableKeyPath<DesignStudioDraft, Value>,
        to value: Value
    ) {
        guard draft[keyPath: keyPath] != value else { return }
        mutate { $0[keyPath: keyPath] = value }
    }

    private func mutate(_ change: (inout DesignStudioDraft) -> Void) {
        var next = draft
        change(&next)
        guard next != draft else { return }
        undoStack.append(draft)
        if undoStack.count > 40 {
            undoStack.removeFirst(undoStack.count - 40)
        }
        redoStack.removeAll()
        draft = next
    }

    private func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(draft)
        draft = previous
    }

    private func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(draft)
        draft = next
    }

    private func applyPreset(_ preset: VisualThemePreset) {
        mutate { value in
            let backgroundBinding = value.theme.backgroundAssetBinding
            value.theme = .preset(preset)
            value.theme.backgroundAssetBinding = backgroundBinding
        }
    }

    private func restoreSelectedPreset() {
        applyPreset(draft.theme.preset)
    }

    @MainActor
    private func importBackground(_ item: PhotosPickerItem) async {
        defer { selectedBackgroundItem = nil }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  UIImage(data: data) != nil else {
                throw LocalAssetStoreError.invalidImageData
            }
            mutate { value in
                value.theme.backgroundAssetBinding = WorkspaceStore.designCanvasBackgroundBinding
                value.backgroundChange = .replacement(data)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func apply() {
        let imageData: Data?
        let removesBackground: Bool
        switch draft.backgroundChange {
        case .unchanged:
            imageData = nil
            removesBackground = false
        case .replacement(let data):
            imageData = data
            removesBackground = false
        case .removed:
            imageData = nil
            removesBackground = true
        }

        do {
            try onApply(DesignStudioResult(
                theme: draft.theme,
                tint: draft.tint,
                symbol: draft.symbol,
                pagePresentation: draft.pagePresentation,
                canvasBackgroundImageData: imageData,
                removesCanvasBackground: removesBackground
            ))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct DesignStudioDraft: Hashable {
    var theme: AppVisualTheme
    var tint: AppTint
    var symbol: String
    var pagePresentation: PagePresentation
    var backgroundChange: DesignStudioBackgroundChange
}

private enum DesignStudioBackgroundChange: Hashable {
    case unchanged
    case replacement(Data)
    case removed
}

private struct StudioSection<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(.headline)
            content
        }
        .makeYourCard()
    }
}

private struct DesignStudioDevicePreview: View {
    let projectName: String
    let draft: DesignStudioDraft
    let backgroundImage: UIImage?

    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatesAccent = false

    private var isDark: Bool {
        switch draft.theme.appearance {
        case .dark: true
        case .light: false
        case .system: systemColorScheme == .dark
        }
    }

    private var palette: BrandPalette { draft.theme.resolvedPalette }

    private var canvas: Color {
        Color(studioHex: isDark ? palette.canvasDarkHex : palette.canvasLightHex)
    }

    private var surface: Color {
        Color(studioHex: isDark ? palette.surfaceDarkHex : palette.surfaceLightHex)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("LIVE PREVIEW")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            ZStack {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(.black)
                ZStack {
                    canvas
                    if let backgroundImage {
                        Image(uiImage: backgroundImage)
                            .resizable()
                            .scaledToFill()
                            .opacity(0.28)
                            .clipped()
                    }
                    previewContent
                }
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .padding(6)
            }
            .frame(maxWidth: 286)
            .aspectRatio(0.62, contentMode: .fit)
            .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Preview of \(projectName) with the current draft design")
        }
        .frame(maxWidth: .infinity)
        .task(id: draft.theme.resolvedMotion) {
            guard !reduceMotion, draft.theme.resolvedMotion == .expressive else {
                animatesAccent = false
                return
            }
            withAnimation(.easeInOut(duration: 0.7).repeatCount(2, autoreverses: true)) {
                animatesAccent = true
            }
        }
    }

    private var previewContent: some View {
        VStack(alignment: .leading, spacing: previewSpacing) {
            HStack {
                Image(systemName: draft.symbol)
                    .foregroundStyle(Color(studioHex: palette.primaryHex))
                    .scaleEffect(animatesAccent ? 1.08 : 1)
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
            }
            Text(projectName)
                .font(.system(size: titleSize, weight: titleWeight, design: draft.theme.typography.fontDesign))
                .foregroundStyle(isDark ? .white : .black)
                .lineLimit(2)
            Text("A tiny app with a visual identity that feels like yours.")
                .font(.system(.caption, design: draft.theme.typography.fontDesign))
                .foregroundStyle(isDark ? Color.white.opacity(0.68) : Color.black.opacity(0.62))

            previewCard
            previewCard.opacity(0.82)

            Text("Continue")
                .font(.system(.caption, design: draft.theme.typography.fontDesign).bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 38)
                .background(Color(studioHex: palette.primaryHex), in: controlShape)
        }
        .padding(draft.theme.density == .compact ? 14 : 18)
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 7) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(studioHex: palette.accentHex))
                .frame(width: 42, height: 6)
            Text("Personal dashboard")
                .font(.system(.subheadline, design: draft.theme.typography.fontDesign).weight(.semibold))
                .foregroundStyle(isDark ? .white : .black)
            Text("Useful, focused, and made for you")
                .font(.system(.caption2, design: draft.theme.typography.fontDesign))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(surface, in: cardShape)
        .overlay { cardStroke }
        .shadow(color: shadowColor, radius: shadowRadius, y: shadowRadius / 2)
    }

    @ViewBuilder
    private var cardStroke: some View {
        switch draft.theme.resolvedStroke {
        case .none:
            EmptyView()
        case .hairline:
            cardShape.stroke(Color.primary.opacity(0.10), lineWidth: 0.7)
        case .accent:
            cardShape.stroke(Color(studioHex: palette.accentHex), lineWidth: 1.4)
        }
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: previewCornerRadius, style: .continuous)
    }

    private var controlShape: RoundedRectangle {
        let radius: CGFloat = switch draft.theme.resolvedControlShape {
        case .native: 10
        case .soft: 14
        case .pill: 22
        case .angular: 3
        }
        return RoundedRectangle(cornerRadius: radius, style: .continuous)
    }

    private var previewCornerRadius: CGFloat {
        switch draft.theme.cornerStyle {
        case .square: 3
        case .soft: 13
        case .round: 24
        }
    }

    private var previewSpacing: CGFloat {
        switch draft.theme.density {
        case .compact: 9
        case .regular: 13
        case .airy: 18
        }
    }

    private var titleSize: CGFloat {
        switch draft.theme.resolvedTypeScale {
        case .compact: 20
        case .balanced: 24
        case .editorial: 28
        case .expressive: 31
        }
    }

    private var titleWeight: Font.Weight {
        switch draft.theme.resolvedTitleWeight {
        case .regular: .regular
        case .semibold: .semibold
        case .bold: .bold
        case .black: .black
        }
    }

    private var shadowColor: Color {
        draft.theme.resolvedElevation == .flat ? .clear : .black.opacity(0.16)
    }

    private var shadowRadius: CGFloat {
        switch draft.theme.resolvedElevation {
        case .flat: 0
        case .subtle: 4
        case .floating: 12
        }
    }
}

extension Color {
    init(studioHex: String) {
        let clean = studioHex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let value = UInt64(clean, radix: 16) ?? 0
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    var studioHex: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(
            format: "#%02X%02X%02X",
            Int((red * 255).rounded()),
            Int((green * 255).rounded()),
            Int((blue * 255).rounded())
        )
    }
}

private extension String {
    var studioLabel: String {
        replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}
