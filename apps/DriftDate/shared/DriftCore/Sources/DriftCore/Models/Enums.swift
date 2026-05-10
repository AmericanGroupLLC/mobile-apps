import Foundation

/// Discovery layers, in increasing radius.
public enum Layer: String, Codable, CaseIterable, Sendable {
    case zip
    case county
    case state
    case server
}

public enum Intent: String, Codable, CaseIterable, Sendable {
    case dating
    case serious
    case friendship
    case open
}

public enum Tone: String, Codable, CaseIterable, Sendable {
    case slow
    case energetic
    case deep
    case meetupReady = "meetup_ready"
}

public enum WaveStatus: String, Codable, Sendable {
    case pending
    case matched
    case passed
}
