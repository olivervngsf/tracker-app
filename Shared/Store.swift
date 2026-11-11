import Foundation
import SwiftData
import WidgetKit

/// Where data lives, plus the few write operations the app and the widgets share.
enum Store {
    /// The App Group both the app and the widget read from.
    /// Derived from the bundle identifier so there is one place to change it (the project's APP_BUNDLE_ID setting).
    static var appGroupID: String {
        var id = Bundle.main.bundleIdentifier ?? "com.olivervngsf.tracker"
        let suffix = ".widget"
        if id.hasSuffix(suffix) { id.removeLast(suffix.count) }
        return "group." + id
    }

    /// True when the shared App Group container is available (needed for widgets to see the app's data).
    static var hasSharedContainer: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) != nil
    }

    static let container: ModelContainer = makeContainer()

    /// A brand-new connection to the saved data.
    /// The app and the widget are separate programs; one long-lived connection can keep showing
    /// old values after the other one saves, so anything that must be current opens a fresh one.
    static func freshContext() -> ModelContext {
        ModelContext(makeContainer())
    }

    private static let changeKey = "externalChangeAt"

    /// When a widget last changed the data. The app compares this when it comes back to the front.
    static var externalChangeStamp: Double {
        UserDefaults(suiteName: appGroupID)?.double(forKey: changeKey) ?? 0
    }

    static func markExternalChange() {
        UserDefaults(suiteName: appGroupID)?.set(Date().timeIntervalSince1970, forKey: changeKey)
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([Tracker.self, Entry.self])

        if hasSharedContainer {
            let shared = ModelConfiguration(
                schema: schema,
                groupContainer: .identifier(appGroupID),
                cloudKitDatabase: .none
            )
            if let container = try? ModelContainer(for: schema, configurations: [shared]) {
                return container
            }
        }

        // Fallback: app-only storage (widgets will show a hint to open the app).
        let local = ModelConfiguration(schema: schema, groupContainer: .none, cloudKitDatabase: .none)
        if let container = try? ModelContainer(for: schema, configurations: [local]) {
            return container
        }

        let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // In-memory storage has no file to fail on.
        return try! ModelContainer(for: schema, configurations: [memory])
    }

    // MARK: Reading

    static func allTrackers(in context: ModelContext) -> [Tracker] {
        let descriptor = FetchDescriptor<Tracker>(sortBy: [SortDescriptor(\.sortOrder)])
        return (try? context.fetch(descriptor)) ?? []
    }

    static func tracker(withID id: String, in context: ModelContext) -> Tracker? {
        allTrackers(in: context).first { $0.uuid.uuidString == id }
    }

    static func entry(for tracker: Tracker, on day: Date, calendar: Calendar = .current) -> Entry? {
        tracker.entries.first { calendar.isDate($0.day, inSameDayAs: day) }
    }

    // MARK: Writing

    /// Sets a day's value. Pass `nil` to clear the day.
    static func setValue(
        _ value: Double?,
        note: String? = nil,
        for tracker: Tracker,
        on day: Date,
        in context: ModelContext,
        calendar: Calendar = .current
    ) {
        let start = calendar.startOfDay(for: day)
        let existing = entry(for: tracker, on: start, calendar: calendar)

        if let value {
            if let existing {
                existing.value = value
                if let note { existing.note = note }
            } else {
                let entry = Entry(day: start, value: value, note: note ?? "")
                context.insert(entry)
                entry.tracker = tracker
            }
        } else if let existing {
            context.delete(existing)
        }
        save(context)
    }

    /// One-tap log for today: toggles a done / not done tracker, or adds one step to a number tracker.
    static func quickLog(_ tracker: Tracker, in context: ModelContext, calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: Date())
        let current = entry(for: tracker, on: today, calendar: calendar)

        switch tracker.kind {
        case .check:
            if let current, current.value >= 1 {
                if current.note.isEmpty {
                    setValue(nil, for: tracker, on: today, in: context, calendar: calendar)
                } else {
                    setValue(0, for: tracker, on: today, in: context, calendar: calendar)
                }
            } else {
                setValue(1, for: tracker, on: today, in: context, calendar: calendar)
            }
        case .number:
            let step = tracker.step > 0 ? tracker.step : 1
            setValue((current?.value ?? 0) + step, for: tracker, on: today, in: context, calendar: calendar)
        }
    }

    static func save(_ context: ModelContext) {
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// First launch only: the five starter trackers. All can be edited or deleted.
    static func seedIfNeeded(in context: ModelContext) {
        let key = "didSeedStarterTrackers"
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: key) else { return }
        defaults.set(true, forKey: key)
        guard allTrackers(in: context).isEmpty else { return }

        let starters: [Tracker] = [
            Tracker(name: "Gym", category: "Fitness", kind: .check, period: .week, goal: 3, sortOrder: 0),
            Tracker(name: "Water", category: "Health", kind: .number, goal: 2.5, unit: "L", step: 0.25, sortOrder: 1),
            Tracker(name: "Steps", category: "Fitness", kind: .number, goal: 8000, unit: "steps", step: 1000, sortOrder: 2),
            Tracker(name: "Calories", category: "Food", kind: .number, goal: 2000, unit: "kcal", step: 100, sortOrder: 3),
            Tracker(name: "Spent", category: "Money", kind: .number, goal: 40, unit: "$", step: 5, isLimit: true, sortOrder: 4)
        ]
        for tracker in starters { context.insert(tracker) }
        save(context)
    }
}
