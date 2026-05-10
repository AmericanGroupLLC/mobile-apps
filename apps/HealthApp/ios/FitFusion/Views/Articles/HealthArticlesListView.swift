import SwiftUI
import FitFusionCore

/// Articles list. Two sources:
/// 1. Always-available bundled `HealthArticleSeed` (works offline / guest).
/// 2. Optional live MyHealthfinder topics via the existing backend
///    `/api/health/topics` route (no auth required).
struct HealthArticlesListView: View {
    @State private var query = ""
    @State private var liveTopics: [LiveTopic] = []
    @State private var loadingLive = false
    @State private var liveError: String?

    private var filteredSeed: [HealthArticleSeed.Article] {
        if query.isEmpty { return HealthArticleSeed.articles }
        return HealthArticleSeed.articles.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.summary.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            Section {
                ForEach(filteredSeed) { article in
                    NavigationLink {
                        HealthArticleDetailView(article: article)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(article.title).font(.body.weight(.semibold))
                            Text(article.summary).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                            Text(article.category).font(.caption2.weight(.bold)).foregroundStyle(.indigo)
                        }
                    }
                }
            } header: {
                Text("Bundled (works offline)")
            }

            Section {
                if liveError != nil {
                    Text("Couldn't load live topics. Bundled articles still available.")
                        .font(.caption2).foregroundStyle(.secondary)
                } else if loadingLive {
                    ProgressView()
                } else {
                    ForEach(liveTopics) { topic in
                        Link(destination: URL(string: topic.url) ?? URL(string: "https://health.gov")!) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(topic.title).font(.body.weight(.semibold))
                                Text(topic.categories ?? "").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("Live (MyHealthfinder)")
            }

            Section {
                NavigationLink {
                    DrugInfoSheet()
                } label: {
                    Label("Look up a medicine (OpenFDA)", systemImage: "pills.circle.fill")
                }
            } header: {
                Text("Drug info")
            }
        }
        .navigationTitle("Health articles")
        .searchable(text: $query, prompt: "Search articles")
        .task { await loadLive() }
        .refreshable { await loadLive() }
    }

    // MARK: - Live topics

    struct LiveTopic: Identifiable, Decodable, Hashable {
        let id: String
        let title: String
        let url: String
        let categories: String?
    }
    struct LiveResponse: Decodable {
        let count: Int?
        let topics: [LiveTopic]
    }

    private func loadLive() async {
        loadingLive = true
        liveError = nil
        defer { loadingLive = false }

        let base = APIConfig.baseURL
        guard let url = URL(string: "\(base)/api/health/topics") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(LiveResponse.self, from: data)
            liveTopics = decoded.topics
        } catch {
            liveError = error.localizedDescription
        }
    }
}
