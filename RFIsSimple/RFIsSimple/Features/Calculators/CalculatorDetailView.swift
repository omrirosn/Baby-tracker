import SwiftUI

/// Routes a calculator identifier to its screen.
///
/// The `switch` is exhaustive, so adding a calculator to `CalculatorID` forces
/// a decision here rather than silently falling through to a placeholder.
struct CalculatorDetailView: View {
    let descriptor: CalculatorDescriptor

    var body: some View {
        switch descriptor.id {
        case .powerConverter:
            PowerConverterView()
        case .voltagePowerImpedance:
            VoltagePowerImpedanceView()
        case .wavelength:
            WavelengthCalculatorView()
        case .freeSpacePathLoss:
            FreeSpacePathLossView()
        case .linkBudget:
            LinkBudgetView()
        case .thermalNoise:
            ThermalNoiseView()
        case .receiverSensitivity:
            ReceiverSensitivityView()
        case .reflectionConverter:
            ReflectionConverterView()
        case .cascadedGainNoiseFigure:
            CascadeView()
        case .eirp:
            RadiatedPowerView()
        case .effectiveAperture:
            EffectiveApertureView()
        case .farFieldDistance:
            FarFieldDistanceView()
        }
    }
}

/// Shown for a calculator that is listed but not yet implemented.
///
/// Nothing uses this today — every calculator in the MVP list calculates — but
/// it is the landing place for the next `CalculatorID` added ahead of its
/// implementation, and it keeps that state honest rather than pretending.
struct ComingSoonView: View {
    let descriptor: CalculatorDescriptor

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.sectionSpacing) {
                ContentUnavailableView {
                    Label(descriptor.title, systemImage: descriptor.systemImage)
                } description: {
                    Text("Planned for a future release. The reference pages below cover the same ground in the meantime.")
                }
                .frame(maxWidth: .infinity)

                NoteCard(kind: .practical, text: descriptor.practicalNote)

                RelatedLinks(articles: descriptor.relatedArticles)
            }
            .padding(AppMetrics.cardPadding)
        }
        .rfPageBackground()
        .navigationTitle(descriptor.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavouriteButton(item: .calculator(descriptor.id))
            }
        }
    }
}

#Preview("Reflection") {
    NavigationStack {
        CalculatorDetailView(descriptor: CalculatorID.reflectionConverter.descriptor)
    }
    .environment(PreferencesStore.preview)
}

#Preview("Link budget") {
    NavigationStack {
        CalculatorDetailView(descriptor: CalculatorID.linkBudget.descriptor)
    }
    .environment(PreferencesStore.preview)
}
