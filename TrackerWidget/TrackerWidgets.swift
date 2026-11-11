import SwiftUI
import WidgetKit
import AppIntents

@main
struct TrackerWidgets: WidgetBundle {
    var body: some Widget {
        TrackerWidget()
        TodayWidget()
    }
}

// MARK: - One tracker (small, large, lock screen)

struct TrackerEntry: TimelineEntry {
    let date: Date
    let snapshot: TrackerSnapshot?
}

struct TrackerProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TrackerEntry {
        TrackerEntry(date: Date(), snapshot: .placeholder)
    }

    func snapshot(for configuration: SelectTrackerIntent, in context: Context) async -> TrackerEntry {
        let snapshot = await SnapshotBuilder.one(id: configuration.tracker?.id)
        return TrackerEntry(date: Date(), snapshot: snapshot ?? .placeholder)
    }

    func timeline(for configuration: SelectTrackerIntent, in context: Context) async -> Timeline<TrackerEntry> {
        let snapshot = await SnapshotBuilder.one(id: configuration.tracker?.id)
        return Timeline(entries: [TrackerEntry(date: Date(), snapshot: snapshot)], policy: .after(nextMidnight()))
    }
}

struct TrackerWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "TrackerWidget", intent: SelectTrackerIntent.self, provider: TrackerProvider()) { entry in
            TrackerWidgetView(entry: entry)
                .environment(\.palette, .dark)
                .containerBackground(for: .widget) { Color.black }
        }
        .configurationDisplayName("Tracker")
        .description("One tracker. Tap the circle to log it.")
        .supportedFamilies([.systemSmall, .systemLarge, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Today (medium)

struct TodayEntry: TimelineEntry {
    let date: Date
    let snapshots: [TrackerSnapshot]
}

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: Date(), snapshots: [.placeholder])
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        Task { @MainActor in
            let snapshots = SnapshotBuilder.all()
            completion(TodayEntry(date: Date(), snapshots: snapshots.isEmpty ? [.placeholder] : snapshots))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        Task { @MainActor in
            let entry = TodayEntry(date: Date(), snapshots: SnapshotBuilder.all())
            completion(Timeline(entries: [entry], policy: .after(nextMidnight())))
        }
    }
}

struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodayWidget", provider: TodayProvider()) { entry in
            TodayWidgetView(entry: entry)
                .environment(\.palette, .dark)
                .containerBackground(for: .widget) { Color.black }
        }
        .configurationDisplayName("Today")
        .description("Your first three trackers. Tap a circle to log it.")
        .supportedFamilies([.systemMedium])
    }
}

/// Widgets refresh just after midnight so "today" moves on.
func nextMidnight() -> Date {
    let calendar = Calendar.current
    let start = calendar.startOfDay(for: Date())
    let next = calendar.date(byAdding: .day, value: 1, to: start) ?? Date().addingTimeInterval(3600)
    return next.addingTimeInterval(5)
}
