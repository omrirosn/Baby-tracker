import SwiftUI

/// About (spec §15), including the engineering disclaimer.
struct AboutView: View {
    private var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        switch (short, build) {
        case let (short?, build?): return "\(short) (\(build))"
        case let (short?, nil): return short
        default: return "—"
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("RF is Simple")
                        .font(.headline)
                    Text("A fast, offline reference and calculation utility for RF work: the formula, the calculation, and the one thing you should not miss.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
            }

            Section("Version") {
                LabeledContent("App version", value: version)
                LabeledContent("Calculators", value: "\(CalculatorCatalog.available.count) of \(CalculatorCatalog.all.count) implemented")
                LabeledContent("Reference pages", value: "\(ReferenceLibrary.all.count)")
            }

            Section {
                Label {
                    Text("Send feedback")
                } icon: {
                    Image(systemName: "envelope")
                }
                .foregroundStyle(.secondary)

                Label {
                    Text("Privacy policy")
                } icon: {
                    Image(systemName: "hand.raised")
                }
                .foregroundStyle(.secondary)
            } header: {
                Text("Contact")
            } footer: {
                Text("Links are placeholders until the first release.")
            }

            Section {
                Text("RF is Simple is an engineering reference and calculation aid. Results should be independently verified before use in safety-critical, regulated, or production designs.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Disclaimer")
            }

            Section {
                Text("Works entirely offline. No account, no analytics, no advertising, and nothing leaves this device.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Privacy")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
