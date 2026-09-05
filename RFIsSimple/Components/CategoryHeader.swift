import SwiftUI

/// Section header used above a category's rows.
struct CategoryHeader: View {
    let category: RFCategory
    var showsSummary: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label {
                Text(category.title)
            } icon: {
                Image(systemName: category.systemImage)
            }
            .font(.subheadline.weight(.semibold))

            if showsSummary {
                Text(category.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Row that opens a category, used on Home.
struct CategoryRow: View {
    let category: RFCategory

    private var counts: String {
        let calculators = CalculatorCatalog.inCategory(category).count
        let articles = ReferenceLibrary.inCategory(category).count
        return "\(calculators) calculators · \(articles) reference"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.systemImage)
                .font(.body)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.title)
                Text(counts)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.title). \(counts).")
    }
}

#Preview("Header") {
    VStack(alignment: .leading, spacing: 24) {
        CategoryHeader(category: .fundamentals)
        CategoryHeader(category: .reflectionAndLines, showsSummary: true)
    }
    .padding()
}

#Preview("Rows") {
    List(RFCategory.allCases) { category in
        CategoryRow(category: category)
    }
}
