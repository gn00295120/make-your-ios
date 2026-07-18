import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct RuntimeDocumentExportView: View {
    let node: ComponentNode
    @Bindable var session: RuntimeSessionState

    @Environment(\.runtimeDesign) private var design
    @State private var isExporting = false
    @State private var exportDocument = RuntimeExportDocument(text: "")
    @State private var exportFileName = "Tiny App Export.txt"
    @State private var exportContentType = UTType.plainText

    private var spec: RuntimeDocumentExportSpec {
        node.documentExport ?? RuntimeDocumentExportSpec(
            fileName: "Tiny App Export",
            format: .plainText,
            contentTemplate: node.value,
            buttonLabel: "Export file"
        )
    }

    private var preview: String {
        session.resolveExportTemplate(spec.contentTemplate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Label(
                    node.title,
                    systemImage: node.symbol.isEmpty ? "square.and.arrow.up.on.square" : node.symbol
                )
                .font(design.bodyFont.weight(.semibold))
                if !node.subtitle.isEmpty {
                    Text(session.resolveTemplate(node.subtitle))
                        .font(design.captionFont)
                        .foregroundStyle(design.secondaryForeground)
                }
            }

            GroupBox("Preview") {
                ScrollView {
                    Text(preview)
                        .font(design.captionFont.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }
                .frame(maxHeight: 160)
            }
            .accessibilityIdentifier("runtime.export.\(node.id).preview")

            Button {
                prepareExport()
            } label: {
                Label(spec.buttonLabel, systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .frame(minHeight: 44)
            .disabled(preview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityHint("Opens Apple's save panel. No file is written until you choose a destination.")
            .accessibilityIdentifier("runtime.export.\(node.id).button")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: exportContentType,
            defaultFilename: exportFileName
        ) { result in
            switch result {
            case .success:
                session.alertMessage = "File exported."
            case .failure(let error):
                if !Self.isCancellation(error) {
                    session.alertMessage = "The file could not be exported."
                }
            }
        }
        .accessibilityIdentifier("runtime.node.\(node.id)")
    }

    private func prepareExport() {
        do {
            let content = try RuntimeDocumentExportCodec.validatedContent(
                preview,
                format: spec.format
            )
            exportDocument = RuntimeExportDocument(text: content)
            exportFileName = RuntimeDocumentExportCodec.normalizedFileName(
                spec.fileName,
                format: spec.format
            )
            exportContentType = RuntimeDocumentExportCodec.contentType(for: spec.format)
            isExporting = true
        } catch {
            session.alertMessage = "This JSON export is not valid yet. Review the preview and try again."
        }
    }

    private static func isCancellation(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError
    }
}

struct RuntimeExportDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.plainText, .json, .commaSeparatedText]

    let text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              data.count <= 8_192,
              let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = text
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = text.data(using: .utf8), data.count <= 8_192 else {
            throw CocoaError(.fileWriteUnknown)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}
