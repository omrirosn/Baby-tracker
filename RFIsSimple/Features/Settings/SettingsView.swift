import SwiftUI

/// Settings (spec §15). Reached from the Home toolbar rather than a fifth tab.
struct SettingsView: View {
    @Environment(PreferencesStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var isConfirmingClear = false

    /// The impedances offered here; a calculator that needs another value takes
    /// it as an input (spec §5.2).
    private static let impedanceOptions: [Double] = [50, 75]

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            Form {
                Section {
                    Picker("Default impedance", selection: $store.defaultImpedanceOhms) {
                        ForEach(Self.impedanceOptions, id: \.self) { value in
                            Text("\(Int(value)) Ω").tag(value)
                        }
                    }
                } header: {
                    Text("Defaults")
                } footer: {
                    Text("Used wherever a calculator needs a system impedance.")
                }

                Section("Preferred units") {
                    Picker("Power", selection: $store.preferredPowerUnit) {
                        ForEach(PowerUnit.allCases) { unit in
                            Text(unit.symbol).tag(unit)
                        }
                    }
                    Picker("Frequency", selection: $store.preferredFrequencyUnit) {
                        ForEach(FrequencyUnit.allCases) { unit in
                            Text(unit.symbol).tag(unit)
                        }
                    }
                    Picker("Distance", selection: $store.preferredLengthUnit) {
                        ForEach(LengthUnit.allCases) { unit in
                            Text(unit.symbol).tag(unit)
                        }
                    }
                }

                Section {
                    Picker("Appearance", selection: $store.appearance) {
                        ForEach(AppearanceOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button("Clear recent history", role: .destructive) {
                        isConfirmingClear = true
                    }
                    .disabled(store.recentItems.isEmpty)
                } footer: {
                    Text("Saved items are kept. Nothing here ever leaves this device.")
                }

                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About RF is Simple", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Clear recent history?",
                isPresented: $isConfirmingClear,
                titleVisibility: .visible
            ) {
                Button("Clear", role: .destructive) { store.clearRecents() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(PreferencesStore.preview)
}
