import Foundation

/// Pure-logic 0..1 scoring of a candidate (target) for a viewer.
///
/// Weights:
///   intent compatibility    : 0.30
///   layer relevance         : 0.20
///   shared interests        : 0.15
///   verification quality    : 0.15
///   recent activity         : 0.10
///   conversation likelihood : 0.10  (proxy via prompt-fill rate)
///
/// Tied scores break by `lastActiveAt` recency.
public enum LayerScorer {
    public static func score(
        viewer: Profile,
        target: Profile,
        layer: Layer,
        now: Date = Date()
    ) -> Double {
        let intent = intentScore(viewer.intent, target.intent)         // 0..1
        let layerScore = layerRelevance(viewer: viewer, target: target, layer: layer)
        let shared  = sharedInterests(viewer.vibeTags, target.vibeTags)
        let verif   = verificationScore(target: target)
        let recency = recentActivityScore(target.lastActiveAt, now: now)
        let convo   = conversationLikelihood(target: target)

        return (intent  * 0.30
              + layerScore * 0.20
              + shared  * 0.15
              + verif   * 0.15
              + recency * 0.10
              + convo   * 0.10)
    }

    static func intentScore(_ a: Intent, _ b: Intent) -> Double {
        if a == b { return 1.0 }
        if a == .open || b == .open { return 0.7 }
        switch (a, b) {
        case (.dating, .serious), (.serious, .dating): return 0.6
        case (.friendship, _), (_, .friendship):       return 0.3
        default:                                       return 0.4
        }
    }

    static func layerRelevance(viewer: Profile, target: Profile, layer: Layer) -> Double {
        switch layer {
        case .zip:    return viewer.zipPrefix3 != nil && viewer.zipPrefix3 == target.zipPrefix3 ? 1.0 : 0.0
        case .county: return viewer.countyFips != nil && viewer.countyFips == target.countyFips ? 0.85 : 0.0
        case .state:  return viewer.stateCode  != nil && viewer.stateCode  == target.stateCode  ? 0.65 : 0.0
        case .server: return 0.4
        }
    }

    static func sharedInterests(_ a: [String], _ b: [String]) -> Double {
        guard !a.isEmpty, !b.isEmpty else { return 0.0 }
        let aset = Set(a.map { $0.lowercased() })
        let bset = Set(b.map { $0.lowercased() })
        let inter = aset.intersection(bset).count
        let union = aset.union(bset).count
        return union == 0 ? 0.0 : Double(inter) / Double(union)
    }

    static func verificationScore(target: Profile) -> Double {
        target.isVerified ? 1.0 : 0.2
    }

    static func recentActivityScore(_ lastActiveAt: Date, now: Date) -> Double {
        let hours = max(0.0, now.timeIntervalSince(lastActiveAt) / 3600.0)
        switch hours {
        case ..<24:    return 1.0
        case ..<24*3:  return 0.75
        case ..<24*7:  return 0.5
        case ..<24*30: return 0.25
        default:       return 0.05
        }
    }

    static func conversationLikelihood(target: Profile) -> Double {
        // Proxy: profiles that filled all 3 prompts and have a voice prompt have
        // a higher chance of giving the user something to reply to.
        let promptScore = Double(min(target.prompts.count, 3)) / 3.0
        let voiceScore  = target.voicePromptUrl != nil ? 1.0 : 0.0
        return (promptScore * 0.7) + (voiceScore * 0.3)
    }

    /// Sort a candidate list by descending score, ties broken by recency.
    public static func sorted(
        candidates: [Profile],
        viewer: Profile,
        layer: Layer,
        now: Date = Date()
    ) -> [Profile] {
        candidates.sorted { lhs, rhs in
            let ls = score(viewer: viewer, target: lhs, layer: layer, now: now)
            let rs = score(viewer: viewer, target: rhs, layer: layer, now: now)
            if abs(ls - rs) > 0.0001 { return ls > rs }
            return lhs.lastActiveAt > rhs.lastActiveAt
        }
    }
}
