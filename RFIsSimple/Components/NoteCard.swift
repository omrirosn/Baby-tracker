import SwiftUI

/// The two kinds of short note that follow a result (spec §6).
struct NoteCard: View {
    enum Kind {
        /// How to read the result.
        case practical
        /// The one thing not to get wrong.
        case mistake

        var title: String {
            switch self {
            case .practical: return "In practice"
            case .mistake: return "Common mistake"
            }
        }

        var systemImage: String {
            switch self {
            case .practical: return "lightbulb"
            case .mistake: return "exclamationmark.triangle"
            }
        }
    }

    let kind: Kind
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text(kind.title)
            } icon: {
                Image(systemName: kind.systemImage)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(kind == .mistake ? Color.orange : Color.accentColor)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .rfCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(kind.title). \(text)")
    }
}

/// Bulleted list used by the "What it means in practice" section of an article.
struct BulletList: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("•")
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                    Text(item)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            NoteCard(kind: .practical, text: CalculatorID.reflectionConverter.descriptor.practicalNote)
            NoteCard(kind: .mistake, text: CalculatorID.reflectionConverter.descriptor.commonMistake ?? "")
            BulletList(items: ReferenceArticleID.vswr.article.inPractice)
                .rfCard()
        }
        .padding()
    }
    .rfPageBackground()
}
