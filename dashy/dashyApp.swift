import SwiftUI
import UserNotifications

@main
struct dashyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        requestPushNotificationPermission()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NSLog("ok")
    }
    
    private func requestPushNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        let authorizeOptions = UNAuthorizationOptions(arrayLiteral: [
            .alert, .sound, .provisional, .providesAppNotificationSettings,
        ])
        center.requestAuthorization(options: authorizeOptions) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error {
                print("Push notification permission error: \(error.localizedDescription)")
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
}
