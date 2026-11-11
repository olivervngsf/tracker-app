import AppIntents
import SwiftData

/// The action behind the tap-to-complete buttons on the widgets.
struct LogIntent: AppIntent {
    static var title: LocalizedStringResource = "Log tracker"
    static var description = IntentDescription("Marks a tracker done for today, or adds one step to it.")

    @Parameter(title: "Tracker ID")
    var trackerID: String

    init() {}

    init(trackerID: String) {
        self.trackerID = trackerID
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        // Fresh connection, so the toggle is based on what is really saved right now.
        let context = Store.freshContext()
        if let tracker = Store.tracker(withID: trackerID, in: context) {
            Store.quickLog(tracker, in: context)
            Store.markExternalChange()
        }
        return .result()
    }
}
