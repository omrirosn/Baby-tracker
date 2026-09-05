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
        case .wavelength:
            WavelengthCalculatorView()
        case .reflectionConverter:
            ReflectionConverterView()
        case .voltagePowerImpedance, .freeSpacePathLoss, .linkBudget, .thermalNoise,
             .receiverSensitivity, .cascadedGainNoiseFigure, .eirp, .effectiveAperture,
             .farFieldDistance:
            ComingSoonView(descriptor: descriptor)
        }
    }
}

/// Shown for a calculator that is listed but not yet implemented.
///
/// It says so plainly and points at the reference pages that cover the same
/// ground, rather than pretending to calculate.
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

#Preview("Planned") {
    NavigationStack {
        CalculatorDetailView(descriptor: CalculatorID.linkBudget.descriptor)
    }
    .environment(PreferencesStore.preview)
}

#Preview("Implemented") {
    NavigationStack {
        CalculatorDetailView(descriptor: CalculatorID.reflectionConverter.descriptor)
    }
    .environment(PreferencesStore.preview)
}
