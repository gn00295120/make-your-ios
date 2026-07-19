import SwiftUI

struct CapabilityReviewSheet: View {
    let capabilities: [AppCapability]
    let onCancel: () -> Void
    let onApprove: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Label("Review new access", systemImage: "hand.raised.fill")
                        .font(.title2.bold())
                    Text(
                        "This version adds the following host-managed capabilities. Access still starts only "
                            + "through the matching component or an approved system action."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    VStack(spacing: 10) {
                        ForEach(capabilities, id: \.self) { capability in
                            capabilityRow(capability)
                        }
                    }

                    Text("Generated documents cannot bypass iOS permission prompts or call arbitrary providers.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .safeAreaInset(edge: .bottom) {
                Button("Enable this version", action: onApprove)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .buttonStyle(.borderedProminent)
                    .tint(MakeYourTheme.brand)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.bar)
                    .accessibilityIdentifier("capability-review.approve")
            }
            .navigationTitle("Capability review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }

    private func capabilityRow(_ capability: AppCapability) -> some View {
        let metadata = CapabilityRegistry.metadata(for: capability)
        return HStack(spacing: 12) {
            Image(systemName: capability.symbol)
                .foregroundStyle(MakeYourTheme.brand)
                .frame(width: 32, height: 32)
                .background(MakeYourTheme.brand.opacity(0.10), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(capability.label).font(.headline)
                Text(metadata.hostEnforcedSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
