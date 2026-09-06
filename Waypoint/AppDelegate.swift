import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Start monitoring immediately — also handles relaunch after significant location change.
        LocationManager.shared.startMonitoring()
        return true
    }
}
