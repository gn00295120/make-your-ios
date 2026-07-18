import Contacts
import ContactsUI
import SwiftUI
import UIKit
import Vision
import VisionKit

struct CameraCaptureSheet: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.cameraCaptureMode = .photo
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onCapture: (UIImage) -> Void
        let onCancel: () -> Void

        init(onCapture: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onCapture = onCapture
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            guard let image = info[.originalImage] as? UIImage else {
                onCancel()
                return
            }
            onCapture(image)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}

struct ScannerCaptureSheet: UIViewControllerRepresentable {
    let kind: DeviceInputKind
    let onCapture: (String) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: recognizedTypes,
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        scanner.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { _ in onCancel() }
        )
        let navigation = UINavigationController(rootViewController: scanner)
        try? scanner.startScanning()
        return navigation
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    private var recognizedTypes: Set<DataScannerViewController.RecognizedDataType> {
        switch kind {
        case .qrCode:
            [.barcode(symbologies: [.qr])]
        case .barcode:
            [.barcode(symbologies: [.ean13, .ean8, .code128, .upce])]
        case .text:
            [.text()]
        default:
            []
        }
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onCapture: (String) -> Void

        init(onCapture: @escaping (String) -> Void) {
            self.onCapture = onCapture
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            switch item {
            case .barcode(let barcode):
                if let value = barcode.payloadStringValue { onCapture(value) }
            case .text(let text):
                onCapture(text.transcript)
            @unknown default:
                break
            }
        }
    }
}

struct ContactCaptureSheet: UIViewControllerRepresentable {
    let onCapture: (String) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let controller = CNContactPickerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let onCapture: (String) -> Void
        let onCancel: () -> Void

        init(onCapture: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
            self.onCapture = onCapture
            self.onCancel = onCancel
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let name = CNContactFormatter.string(from: contact, style: .fullName) ?? "Contact"
            let phone = contact.phoneNumbers.first?.value.stringValue
            let email = contact.emailAddresses.first?.value as String?
            let details = [name, phone, email]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            onCapture(details.joined(separator: " · "))
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            onCancel()
        }
    }
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
