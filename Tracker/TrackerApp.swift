import SwiftUI
import SwiftData
import UIKit

@main
struct TrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    @State private var container = Store.container
    @State private var generation = 0
    @State private var seenChange = Store.externalChangeStamp

    var body: some Scene {
        WindowGroup {
            RootView()
                .id(generation)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            // A widget logged something while the app was in the background: reconnect to see it.
            let stamp = Store.externalChangeStamp
            if stamp != seenChange {
                seenChange = stamp
                container = Store.makeContainer()
                generation += 1
            }
        }
    }
}

/// Normal phones stay upright. Big screens (iPhone Duo open) may also turn sideways.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        let bounds = window?.windowScene?.screen.bounds ?? window?.bounds ?? UIScreen.main.bounds
        return min(bounds.width, bounds.height) >= 580 ? [.portrait, .landscape] : .portrait
    }
}
