import SwiftUI
import SwiftData

@main
struct TrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(Store.container)
    }
}
