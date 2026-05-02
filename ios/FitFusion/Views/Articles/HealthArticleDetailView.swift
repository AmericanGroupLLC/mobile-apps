import SwiftUI
import FitFusionCore

/// Render one bundled article. Uses simple AttributedString markdown parsing
/// so bullets and bold render naturally without an external library.
struct HealthArticleDetailView: View {
    let article: HealthArticleSeed.Article

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(article.category.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.indigo)
                Text(article.title).font(.largeTitle).bold()
                Text(article.summary).font(.headline).foregroundStyle(.secondary)
                Divider().padding(.vertical, 4)
                if let attributed = try? AttributedString(markdown: article.body,
                                                          options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                    Text(attributed).font(.body)
                } else {
                    Text(article.body).font(.body)
                }
            }
            .padding()
        }
        .navigationTitle("Article")
        .navigationBarTitleDisplayMode(.inline)
    }
}
