import SwiftUI
import SwiftData
import UIKit

@main
struct TrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(Store.container)
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
