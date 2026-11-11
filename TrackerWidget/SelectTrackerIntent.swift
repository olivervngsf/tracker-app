import AppIntents
import SwiftData
import WidgetKit

/// A tracker as it appears in the widget's "Edit Widget" picker.
struct TrackerEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Tracker"
    static var defaultQuery = TrackerEntityQuery()

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct TrackerEntityQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [String]) async throws -> [TrackerEntity] {
        loadAll().filter { identifiers.contains($0.id) }
    }

    @MainActor
    func suggestedEntities() async throws -> [TrackerEntity] {
        loadAll()
    }

    @MainActor
    func defaultResult() async -> TrackerEntity? {
        loadAll().first
    }

    @MainActor
    private func loadAll() -> [TrackerEntity] {
        let context = Store.freshContext()
        return Store.allTrackers(in: context).map {
            TrackerEntity(id: $0.uuid.uuidString, name: $0.name)
        }
    }
}

/// Long-press a widget, tap Edit Widget, pick which tracker it shows.
struct SelectTrackerIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Choose tracker"
    static var description = IntentDescription("Pick which tracker this widget shows.")

    @Parameter(title: "Tracker")
    var tracker: TrackerEntity?
}
