import Foundation
import SwiftData

/// What a tracker records each day.
enum TrackerKind: String, CaseIterable, Identifiable {
    case check   // done / not done (e.g. Gym)
    case number  // an amount (e.g. water, steps, calories, money)

    var id: String { rawValue }
}

/// How often a done / not done goal repeats.
enum GoalPeriod: String, CaseIterable, Identifiable {
    case day, week, month

    var id: String { rawValue }

    var label: String {
        switch self {
        case .day: return "a day"
        case .week: return "a week"
        case .month: return "a month"
        }
    }

    var component: Calendar.Component {
        switch self {
        case .day: return .day
        case .week: return .weekOfYear
        case .month: return .month
        }
    }
}

@Model
final class Tracker {
    var uuid: UUID = UUID()
    var name: String = ""
    var category: String = ""
    var kindRaw: String = "check"
    var periodRaw: String = "week"
    /// check: how many times per period. number: the daily amount.
    var goal: Double = 1
    var unit: String = ""
    /// number only: how much one tap on "+" adds.
    var step: Double = 1
    /// number only: true when the goal is a ceiling (e.g. spending).
    var isLimit: Bool = false
    var sortOrder: Int = 0
    var showOnWidget: Bool = true
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Entry.tracker)
    var entries: [Entry] = []

    init(
        name: String,
        category: String = "",
        kind: TrackerKind = .check,
        period: GoalPeriod = .week,
        goal: Double = 1,
        unit: String = "",
        step: Double = 1,
        isLimit: Bool = false,
        sortOrder: Int = 0
    ) {
        self.uuid = UUID()
        self.name = name
        self.category = category
        self.kindRaw = kind.rawValue
        self.periodRaw = period.rawValue
        self.goal = goal
        self.unit = unit
        self.step = step
        self.isLimit = isLimit
        self.sortOrder = sortOrder
        self.showOnWidget = true
        self.createdAt = Date()
    }
}

/// One day's log for one tracker.
@Model
final class Entry {
    /// Start of the day this entry belongs to.
    var day: Date = Date()
    var value: Double = 0
    var note: String = ""
    var tracker: Tracker?

    init(day: Date, value: Double, note: String = "") {
        self.day = day
        self.value = value
        self.note = note
    }
}
