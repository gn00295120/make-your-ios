import SwiftUI

struct PrivacySafetyView: View {
    var body: some View {
        List {
            Section("On this iPhone") {
                privacyRow(
                    symbol: "doc.text.fill",
                    title: "Projects and records",
                    detail: "Mini apps, records, watchlists, and cached rates stay in local app storage."
                )
                privacyRow(
                    symbol: "photo.fill",
                    title: "Selected photos",
                    detail: "Photos stay in project-local storage and are never attached to AI requests."
                )
                privacyRow(
                    symbol: "key.fill",
                    title: "OpenAI API key",
                    detail: "Stored in Keychain with When Unlocked, This Device Only protection."
                )
            }

            Section("When data leaves the device") {
                Text(
                    "App generation sends your builder prompt and current declarative app document "
                        + "directly to OpenAI after you enable AI requests."
                )
                Text(
                    "An AI tool inside a mini app sends only the task and text shown on its review screen. "
                        + "It does not attach photos, records, other projects, or device data."
                )
                Text(
                    "Live FX Watch sends selected ISO currency codes to Frankfurter to retrieve the latest "
                        + "available daily reference rates."
                )
            }

            Section("Your controls") {
                Text("Remove the API key from AI Key at any time.")
                Text("Delete a mini app from My Apps to remove its document and project photos.")
                Text("Delete MakeYour from iPhone to remove all remaining local app data.")
            }

            Section("No tracking") {
                Text(
                    "MakeYour has no account system, advertising SDK, analytics SDK, or tracking. "
                        + "Third-party services are contacted only to provide a feature you request."
                )
            }

            Section("Third-party policies") {
                Link("OpenAI privacy policy", destination: URL(string: "https://openai.com/policies/privacy-policy/")!)
                Link("Frankfurter API", destination: URL(string: "https://frankfurter.dev/")!)
            }

            Section {
                Text("Version \(appVersion)")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Privacy & Safety")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func privacyRow(symbol: String, title: String, detail: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: symbol).foregroundStyle(MakeYourTheme.brand)
        }
        .accessibilityElement(children: .combine)
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return "\(version ?? "—") (\(build ?? "—"))"
    }
}
