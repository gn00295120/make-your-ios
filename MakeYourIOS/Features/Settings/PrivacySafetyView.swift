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
                    title: "Selected and captured data",
                    detail: "Photos, voice audio, accepted transcripts, scans, chosen contacts, files, "
                        + "location, and step results "
                        + "stay in project-local storage and are never attached to AI requests automatically."
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
                        + "An accepted transcript may appear as editable text, but audio is never attached. "
                        + "It does not attach photos, records, other projects, or device data."
                )
                Text(
                    "Live FX Watch sends selected ISO currency codes to Frankfurter to retrieve the latest "
                        + "available daily reference rates."
                )
                Text(
                    "News and market components contact only their compiled providers. Sharing opens "
                        + "Apple’s reviewable share sheet; nothing is sent until you choose a destination."
                )
            }

            Section("Native capability boundary") {
                Text(
                    "AI can compose only abilities compiled into MakeYour. Every ability has a fixed privacy "
                        + "contract, and new sensitive access is reviewed before a generated version is enabled."
                )
                NavigationLink("View \(CapabilityRegistry.orderedMetadata.count) compiled abilities") {
                    CapabilityCatalogView()
                }
            }

            Section("Shortcuts and Siri") {
                Text(
                    "A tiny app appears in Apple Shortcuts only after its generated version includes "
                        + "the visible Shortcuts access block and you approve that capability. iOS receives "
                        + "only opted-in apps' stable IDs, names, and safe icons—not prompts, state, media, or keys."
                )
                Text(
                    "The fixed shortcut requires local device authentication and only opens MakeYour in "
                        + "the foreground. Remove the block or delete the tiny app to revoke its listing."
                )
            }

            Section("Your controls") {
                Text("Remove OpenAI and market-provider keys with their in-app Remove controls at any time.")
                Text(
                    "Delete a mini app from My Apps to remove its document, project assets, runtime data, "
                        + "scheduled notifications, and Shortcuts eligibility."
                )
                Text("Deleting MakeYour from iPhone removes its sandboxed projects, assets, and runtime data.")
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
                Link("BBC News", destination: URL(string: "https://www.bbc.com/news")!)
                Link("NPR", destination: URL(string: "https://www.npr.org/")!)
                Link("Twelve Data", destination: URL(string: "https://twelvedata.com/")!)
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

private struct CapabilityCatalogView: View {
    var body: some View {
        List {
            ForEach(CapabilityCategory.allCases, id: \.self) { category in
                let entries = CapabilityRegistry.orderedMetadata.filter { $0.category == category }
                if !entries.isEmpty {
                    Section(category.label) {
                        ForEach(entries, id: \.capability) { entry in
                            Label {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.capability.label).font(.headline)
                                    Text(entry.hostEnforcedSummary)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                    if let note = entry.frameworkOrPermissionNote {
                                        Text(note).font(.caption2).foregroundStyle(.tertiary)
                                    }
                                }
                            } icon: {
                                Image(systemName: entry.capability.symbol)
                                    .foregroundStyle(MakeYourTheme.brand)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Host capabilities")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension CapabilityCategory {
    var label: String {
        switch self {
        case .data: "Data"
        case .computation: "Computation"
        case .notifications: "Notifications"
        case .media: "Media"
        case .deviceInput: "Camera and scanning"
        case .network: "Network"
        case .intelligence: "AI"
        case .location: "Location"
        case .people: "People"
        case .files: "Files"
        case .motion: "Motion"
        case .sharing: "Sharing"
        case .systemFeedback: "System feedback"
        case .calendar: "Calendar"
        case .automation: "Automation"
        }
    }
}
