import Foundation
import SwiftData

/// A plain copy of one tracker's numbers, safe to hand to a widget view.
struct TrackerSnapshot: Identifiable {
    let id: String
    let name: String
    let kind: TrackerKind
    /// Big text: "1/3" or "1.5".
    let headline: String
    /// Small line under it: "gym this week" or "of 2.5 L water".
    let caption: String
    /// Row text on the medium widget: "1 of 3".
    let rowText: String
    let doneToday: Bool
    /// 0...1 toward today's goal (number trackers with a target only).
    let progressToday: Double
    let week: [DotState]
    /// 0...1 toward the goal for each day in `week`.
    let weekProgress: [Double]
    let year: [DotState]
    let yearDone: Int

    static let placeholder = TrackerSnapshot(
        id: "placeholder",
        name: "Gym",
        kind: .check,
        headline: "1/3",
        caption: "gym this week",
        rowText: "1 of 3",
        doneToday: false,
        progressToday: 0,
        week: [.done, .open, .todayOpen, .future, .future, .future, .future],
        weekProgress: Array(repeating: 0, count: 7),
        year: (0..<365).map { (index: Int) -> DotState in
            if index >= 200 { return .future }
            return index % 3 == 0 ? .done : .open
        },
        yearDone: 67
    )
}

enum SnapshotBuilder {
    @MainActor
    static func all() -> [TrackerSnapshot] {
        let context = Store.freshContext()
        return Store.allTrackers(in: context)
            .filter { $0.showOnWidget }
            .map { make($0) }
    }

    @MainActor
    static func one(id: String?) -> TrackerSnapshot? {
        let snapshots = all()
        if let id, let match = snapshots.first(where: { $0.id == id }) { return match }
        return snapshots.first
    }

    private static func make(_ tracker: Tracker) -> TrackerSnapshot {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let values = tracker.valuesByDay(calendar: calendar)
        let weekDays = calendar.days(in: .weekOfYear, containing: today)
        let yearDays = calendar.days(in: .year, containing: today)
        let doneToday = tracker.isDone(values[today])
        let lowerName = tracker.name.lowercased()

        let headline: String
        let caption: String
        let rowText: String

        switch tracker.kind {
        case .check:
            let goal = max(1, Int(tracker.goal))
            if tracker.period == .day {
                headline = doneToday ? "1/1" : "0/1"
                caption = "\(lowerName) today"
                rowText = doneToday ? "done" : "not yet"
            } else {
                let days = calendar.days(in: tracker.period.component, containing: today)
                let count = tracker.doneCount(in: days, values: values)
                headline = "\(count)/\(goal)"
                caption = "\(lowerName) this \(tracker.period == .week ? "week" : "month")"
                rowText = "\(count) of \(goal)"
            }
        case .number:
            let value = values[today] ?? 0
            headline = formatAmount(value)
            caption = "of \(formatAmount(tracker.goal)) \(tracker.unit) \(lowerName)"
                .replacingOccurrences(of: "  ", with: " ")
            rowText = "\(formatAmount(value)) of \(formatAmount(tracker.goal)) \(tracker.unit)"
                .trimmingCharacters(in: .whitespaces)
        }

        return TrackerSnapshot(
            id: tracker.uuid.uuidString,
            name: tracker.name,
            kind: tracker.kind,
            headline: headline,
            caption: caption,
            rowText: rowText,
            doneToday: doneToday,
            progressToday: tracker.progress(values[today]),
            week: tracker.states(for: weekDays, values: values, today: today),
            weekProgress: weekDays.map { tracker.progress(values[$0]) },
            year: tracker.states(for: yearDays, values: values, today: today),
            yearDone: tracker.doneCount(in: yearDays, values: values)
        )
    }
}
