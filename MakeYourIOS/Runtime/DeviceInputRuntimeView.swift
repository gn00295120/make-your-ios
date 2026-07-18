import Foundation
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import VisionKit

struct DeviceInputRuntimeView: View {
    private struct StoredResult: Codable {
        var value: String
    }

    let projectID: UUID
    let node: ComponentNode
    let tint: AppTint
    let theme: AppVisualTheme
    @Bindable var session: RuntimeSessionState

    @Environment(LocalAssetStore.self) private var assetStore
    @Environment(\.openURL) private var openURL
    @State private var result = ""
    @State private var assetRevision = 0
    @State private var isPresentingCamera = false
    @State private var isPresentingScanner = false
    @State private var isPresentingContactPicker = false
    @State private var isPresentingDocumentPicker = false
    @State private var isPresentingShareSheet = false
    @State private var statusMessage: String?
    @State private var showsSettingsButton = false
    @State private var shareItems: [Any] = []
    @State private var locationCapture = CurrentLocationCapture()
    @State private var pedometerReader = PedometerReader()

    private let stateStore = ProjectRuntimeStateStore()

    private var spec: DeviceInputSpec {
        node.deviceInput ?? DeviceInputSpec(
            kind: .qrCode,
            buttonLabel: "Start scanning",
            resultLabel: "Scanned result",
            allowsRepeat: true
        )
    }

    private var storedImage: UIImage? {
        _ = assetRevision
        return assetStore.image(projectID: projectID, binding: node.binding)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            capturedContent

            Button(action: beginCapture) {
                Label(spec.buttonLabel, systemImage: buttonSymbol)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(tint.color)
            .disabled(!spec.allowsRepeat && hasResult)

            Label(privacyNote, systemImage: "lock.shield.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let statusMessage {
                VStack(alignment: .leading, spacing: 6) {
                    Label(statusMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if showsSettingsButton,
                       let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        Button("Open Settings") { openURL(settingsURL) }
                            .font(.caption.weight(.semibold))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear(perform: load)
        .sheet(isPresented: $isPresentingCamera) {
            CameraCaptureSheet { image in
                saveCapturedImage(image)
                isPresentingCamera = false
            } onCancel: {
                isPresentingCamera = false
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isPresentingScanner) {
            ScannerCaptureSheet(kind: spec.kind) { scannedValue in
                saveScannedValue(scannedValue)
                isPresentingScanner = false
            } onCancel: {
                isPresentingScanner = false
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isPresentingContactPicker) {
            ContactCaptureSheet { contactValue in
                saveScannedValue(contactValue)
                isPresentingContactPicker = false
            } onCancel: {
                isPresentingContactPicker = false
            }
        }
        .sheet(isPresented: $isPresentingShareSheet) {
            ActivityShareSheet(items: shareItems)
        }
        .fileImporter(
            isPresented: $isPresentingDocumentPicker,
            allowedContentTypes: [.plainText, .json, .commaSeparatedText],
            allowsMultipleSelection: false,
            onCompletion: importDocument
        )
    }
}

private extension DeviceInputRuntimeView {
    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(node.title, systemImage: node.symbol.isEmpty ? buttonSymbol : node.symbol)
                .font(.headline)
            if !node.subtitle.isEmpty {
                Text(node.subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var capturedContent: some View {
        if spec.kind.requiresPhotoCapture, let storedImage {
            Image(uiImage: storedImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .aspectRatio(4 / 3, contentMode: .fit)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
                .accessibilityLabel(spec.resultLabel)
        } else if !result.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                Text(spec.resultLabel).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Text(result)
                    .font(.body.monospaced())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(tint.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var hasResult: Bool {
        spec.kind.requiresPhotoCapture ? storedImage != nil : !result.isEmpty
    }

    private var buttonSymbol: String {
        switch spec.kind {
        case .cameraPhoto: "camera.fill"
        case .qrCode: "qrcode.viewfinder"
        case .barcode: "barcode.viewfinder"
        case .text: "text.viewfinder"
        case .currentLocation: "location.fill"
        case .contact: "person.crop.circle.badge.plus"
        case .documentText: "doc.badge.plus"
        case .pedometer: "figure.walk.motion"
        case .shareText: "square.and.arrow.up"
        case .copyText: "doc.on.clipboard"
        case .haptic: "waveform"
        }
    }

    private var privacyNote: String {
        switch spec.kind {
        case .cameraPhoto:
            "Photos are stored only inside this tiny app on this iPhone."
        case .qrCode, .barcode, .text:
            "Scanning starts only after you tap and the result stays on this iPhone."
        case .currentLocation:
            "Location is requested once after you tap and is not tracked in the background."
        case .contact:
            "You choose one contact in Apple’s picker; MakeYour cannot browse your address book."
        case .documentText:
            "Only the text file you choose is read and stored in this tiny app."
        case .pedometer:
            "Today’s step count is requested after you tap and remains on this iPhone."
        case .shareText:
            "Nothing is shared until you choose a destination in Apple’s share sheet."
        case .copyText:
            "The configured text is copied only after you tap."
        case .haptic:
            "This action plays a local tactile confirmation and stores no sensor data."
        }
    }

    private func beginCapture() {
        switch spec.kind {
        case .cameraPhoto, .qrCode, .barcode, .text:
            beginCameraFeature()
        case .currentLocation:
            captureCurrentLocation()
        case .contact:
            statusMessage = nil
            isPresentingContactPicker = true
        case .documentText:
            statusMessage = nil
            isPresentingDocumentPicker = true
        case .pedometer:
            readPedometer()
        case .shareText:
            let payload = actionPayload
            guard !payload.isEmpty else {
                statusMessage = "Add text to this component before sharing."
                return
            }
            shareItems = [payload]
            isPresentingShareSheet = true
            saveScannedValue("Share sheet opened")
        case .copyText:
            let payload = actionPayload
            guard !payload.isEmpty else {
                statusMessage = "Add text to this component before copying."
                return
            }
            UIPasteboard.general.string = payload
            saveScannedValue("Copied to clipboard")
        case .haptic:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            saveScannedValue("Haptic played")
        }
    }

    private var actionPayload: String {
        let configured = node.value.trimmingCharacters(in: .whitespacesAndNewlines)
        return configured.isEmpty
            ? session.binding(for: node.binding, fallback: "")
            : configured
    }

    private func beginCameraFeature() {
        Task {
            guard await CameraAuthorization.requestAccess() else {
                statusMessage = "Camera access is off. Enable it in Settings to use this component."
                showsSettingsButton = true
                return
            }
            showsSettingsButton = false

            if spec.kind.requiresPhotoCapture {
                guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                    statusMessage = "Camera capture requires a supported physical device."
                    return
                }
                statusMessage = nil
                isPresentingCamera = true
            } else {
                guard DataScannerViewController.isSupported,
                      DataScannerViewController.isAvailable else {
                    statusMessage = "Live scanning requires a supported physical device."
                    return
                }
                statusMessage = nil
                isPresentingScanner = true
            }
        }
    }

    private func captureCurrentLocation() {
        statusMessage = nil
        locationCapture.capture { captureResult in
            Task { @MainActor in
                switch captureResult {
                case .success(let location):
                    let coordinate = location.coordinate
                    saveScannedValue(
                        String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
                    )
                case .failure(.denied):
                    statusMessage = "Location access is off. Enable it in Settings to use this component."
                    showsSettingsButton = true
                case .failure(let error):
                    statusMessage = error.localizedDescription
                }
            }
        }
    }

    private func readPedometer() {
        statusMessage = nil
        Task {
            do {
                let steps = try await pedometerReader.todaySteps()
                saveScannedValue("\(steps.formatted()) steps today")
            } catch {
                statusMessage = error.localizedDescription
            }
        }
    }

    private func importDocument(_ selection: Result<[URL], Error>) {
        do {
            let url = try selection.get().first
            guard let url else { return }
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard size <= 256_000 else { throw DeviceCaptureError.documentTooLarge }
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            guard let text = String(data: data, encoding: .utf8) else {
                throw DeviceCaptureError.unreadableDocument
            }
            saveScannedValue(String(text.prefix(2_000)))
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func load() {
        if let saved = try? stateStore.load(
            StoredResult.self,
            projectID: projectID,
            nodeID: node.id,
            namespace: "device-input"
        ) {
            result = saved.value
            session.set(saved.value, for: node.binding)
        }
    }

    private func saveCapturedImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.92) else {
            statusMessage = "The captured photo could not be saved."
            return
        }
        do {
            try assetStore.saveImageData(data, projectID: projectID, binding: node.binding)
            assetRevision += 1
            result = spec.resultLabel
            session.set(result, for: node.binding)
            try stateStore.save(
                StoredResult(value: result),
                projectID: projectID,
                nodeID: node.id,
                namespace: "device-input"
            )
            statusMessage = nil
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func saveScannedValue(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        result = String(trimmed.prefix(2_000))
        session.set(result, for: node.binding)
        do {
            try stateStore.save(
                StoredResult(value: result),
                projectID: projectID,
                nodeID: node.id,
                namespace: "device-input"
            )
            statusMessage = nil
        } catch {
            statusMessage = "The scanned result could not be saved."
        }
    }
}
