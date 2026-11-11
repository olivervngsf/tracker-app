import Foundation

/// How one day is drawn.
enum DotState: Hashable {
    case done        // filled
    case open        // ring: not done
    case todayOpen   // orange ring
    case todayDone   // orange filled
    case future      // faint ring
    case blank       // empty slot in a calendar grid
}

extension Tracker {
    var kind: TrackerKind {
        get { TrackerKind(rawValue: kindRaw) ?? .check }
        set { kindRaw = newValue.rawValue }
    }

    var period: GoalPeriod {
        get { GoalPeriod(rawValue: periodRaw) ?? .week }
        set { periodRaw = newValue.rawValue }
    }

    /// Logged value per day, keyed by start-of-day.
    func valuesByDay(calendar: Calendar = .current) -> [Date: Double] {
        var map: [Date: Double] = [:]
        for entry in entries {
            map[calendar.startOfDay(for: entry.day), default: 0] += entry.value
        }
        return map
    }

    /// Does this day's value count as done?
    func isDone(_ value: Double?) -> Bool {
        guard let value else { return false }
        switch kind {
        case .check:
            return value >= 1
        case .number:
            return isLimit ? value <= goal : value >= goal
        }
    }

    func state(for day: Date, values: [Date: Double], today: Date) -> DotState {
        let done = isDone(values[day])
        if day == today { return done ? .todayDone : .todayOpen }
        if day > today { return .future }
        return done ? .done : .open
    }

    func states(for days: [Date], values: [Date: Double], today: Date) -> [DotState] {
        days.map { state(for: $0, values: values, today: today) }
    }

    func doneCount(in days: [Date], values: [Date: Double]) -> Int {
        days.reduce(0) { $0 + (isDone(values[$1]) ? 1 : 0) }
    }

    /// Short progress line, e.g. "1 of 3 this week" or "1.5 of 2.5 L".
    func summary(values: [Date: Double], today: Date, calendar: Calendar = .current) -> String {
        switch kind {
        case .check:
            if period == .day {
                return isDone(values[today]) ? "Done today" : "Not yet today"
            }
            let days = calendar.days(in: period.component, containing: today)
            let count = doneCount(in: days, values: values)
            let word = period == .week ? "week" : "month"
            return "\(count) of \(Int(goal)) this \(word)"
        case .number:
            let value = values[today] ?? 0
            let text = "\(formatAmount(value)) of \(formatAmount(goal)) \(unit)"
            return text.trimmingCharacters(in: .whitespaces)
        }
    }
}
