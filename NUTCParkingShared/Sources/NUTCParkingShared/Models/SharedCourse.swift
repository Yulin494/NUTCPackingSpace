import Foundation

public struct SharedCourse: Codable, Identifiable {
    public let id: String
    public let name: String
    public let instructor: String
    public let room: String
    public let weekday: Int    // 1=Mon ... 7=Sun
    public let startPeriod: Int
    public let endPeriod: Int
    public let color: String

    public init(id: String, name: String, instructor: String, room: String,
                weekday: Int, startPeriod: Int, endPeriod: Int, color: String) {
        self.id = id
        self.name = name
        self.instructor = instructor
        self.room = room
        self.weekday = weekday
        self.startPeriod = startPeriod
        self.endPeriod = endPeriod
        self.color = color
    }

    // NUTC period → (hour, minute) start time
    public static let periodStartTimes: [(hour: Int, minute: Int)] = [
        (8, 10), (9, 10), (10, 10), (11, 10),
        (12, 10), (13, 10), (14, 10), (15, 10),
        (16, 10), (17, 10), (18, 10), (19, 10),
        (20, 10), (21, 10),
    ]

    public var startTime: (hour: Int, minute: Int)? {
        guard startPeriod >= 1 && startPeriod <= 14 else { return nil }
        return SharedCourse.periodStartTimes[startPeriod - 1]
    }
}

public struct SharedScheduleCache {
    private static let suiteName = "group.com.yulin494.NUTCParkingSpace"
    private static let key = "sharedCourses"

    public static func save(_ courses: [SharedCourse]) {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = try? JSONEncoder().encode(courses)
        else { return }
        defaults.set(data, forKey: key)
    }

    public static func load() -> [SharedCourse] {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: key),
              let courses = try? JSONDecoder().decode([SharedCourse].self, from: data)
        else { return [] }
        return courses
    }
}
