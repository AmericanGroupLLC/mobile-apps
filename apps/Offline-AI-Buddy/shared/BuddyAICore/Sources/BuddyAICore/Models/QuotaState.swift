import Foundation

/// Per-profile, per-day rolling chat-quota state.
public struct QuotaState: Codable, Hashable, Sendable {
    public let profileId: UUID
    /// Calendar day in `yyyy-MM-dd` form; rolls over at local midnight.
    public var day: String
    public var chatsUsed: Int
    public var adUnlocks: Int        // each watched ad = +5 chats

    public init(profileId: UUID, day: String, chatsUsed: Int = 0, adUnlocks: Int = 0) {
        self.profileId = profileId
        self.day = day
        self.chatsUsed = chatsUsed
        self.adUnlocks = adUnlocks
    }

    public static func dayString(for date: Date, calendar: Calendar = .current) -> String {
        let f = DateFormatter()
        f.calendar = calendar
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = calendar.timeZone
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
