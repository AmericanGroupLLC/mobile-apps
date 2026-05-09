// Clock domain models. No platform deps.
import Foundation

public enum Weekday: Int, CaseIterable, Codable, Sendable {
    case sun = 1, mon, tue, wed, thu, fri, sat
    public var shortLabel: String {
        switch self {
        case .sun: return "Sun"; case .mon: return "Mon"; case .tue: return "Tue"
        case .wed: return "Wed"; case .thu: return "Thu"; case .fri: return "Fri"; case .sat: return "Sat"
        }
    }
}

public struct Alarm: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var label: String
    public var hour: Int      // 0...23
    public var minute: Int    // 0...59
    public var repeatOn: Set<Weekday>
    public var soundName: String
    public var enabled: Bool

    public init(
        id: UUID = UUID(),
        label: String = "Alarm",
        hour: Int,
        minute: Int,
        repeatOn: Set<Weekday> = [],
        soundName: String = "default",
        enabled: Bool = true
    ) {
        self.id = id
        self.label = label
        self.hour = max(0, min(23, hour))
        self.minute = max(0, min(59, minute))
        self.repeatOn = repeatOn
        self.soundName = soundName
        self.enabled = enabled
    }
}

public struct WorldClockPin: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var timeZoneIdentifier: String
    public var sortIndex: Int
    public init(id: UUID = UUID(), timeZoneIdentifier: String, sortIndex: Int) {
        self.id = id
        self.timeZoneIdentifier = timeZoneIdentifier
        self.sortIndex = sortIndex
    }
}

public struct BedtimeSchedule: Codable, Equatable, Sendable {
    public var bedtimeHour: Int
    public var bedtimeMinute: Int
    public var wakeHour: Int
    public var wakeMinute: Int
    public var enabledOn: Set<Weekday>
    public init(bedtimeHour: Int, bedtimeMinute: Int, wakeHour: Int, wakeMinute: Int, enabledOn: Set<Weekday> = []) {
        self.bedtimeHour = bedtimeHour
        self.bedtimeMinute = bedtimeMinute
        self.wakeHour = wakeHour
        self.wakeMinute = wakeMinute
        self.enabledOn = enabledOn
    }
}
