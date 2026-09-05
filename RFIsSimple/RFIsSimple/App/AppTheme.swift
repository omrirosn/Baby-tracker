import SwiftUI
import UIKit

/// Layout constants shared by every screen.
///
/// The visual language is deliberately plain: one accent colour, a neutral
/// grouped background, and cards that carry the content (spec §12).
enum AppMetrics {
    static let cardCornerRadius: CGFloat = 14
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 16
    /// Apple's minimum, applied to every control that can be tapped.
    static let minimumTapTarget: CGFloat = 44
}

extension Color {
    /// Page background behind cards.
    static let rfGroupedBackground = Color(uiColor: .systemGroupedBackground)
    /// Card background, one step forward from the page.
    static let rfCardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    /// Fill behind a value or a chip.
    static let rfFieldBackground = Color(uiColor: .tertiarySystemGroupedBackground)
}

private struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppMetrics.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color.rfCardBackground,
                in: RoundedRectangle(cornerRadius: AppMetrics.cardCornerRadius, style: .continuous)
            )
    }
}

extension View {
    /// Standard card: padded, full width, rounded, on the card background.
    func rfCard() -> some View {
        modifier(CardModifier())
    }

    /// Applies the page background used behind every scrolling screen.
    func rfPageBackground() -> some View {
        background(Color.rfGroupedBackground)
    }
}

/// Titles used above the cards inside a scrolling calculator or article page.
struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: AppMetrics.sectionSpacing) {
            SectionLabel(text: "Inputs")
            Text("Card content").rfCard()
            SectionLabel(text: "Results")
            Text("Another card").rfCard()
        }
        .padding()
    }
    .rfPageBackground()
}
