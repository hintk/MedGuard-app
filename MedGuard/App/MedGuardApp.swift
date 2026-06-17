import SwiftUI

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: - Foreground notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    // MARK: - Handle notification actions
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case "MARK_TAKEN":
            if let medicationId = userInfo["medicationId"] as? String {
                // Post notification so MedicationStore can handle on main actor
                NotificationCenter.default.post(name: .markMedicationTaken, object: nil, userInfo: ["medicationId": medicationId])
            }

        case "CALL_CHILD":
            // Open the app to remind the elderly — no phone number stored
            break

        default:
            break
        }

        completionHandler()
    }
}

extension Notification.Name {
    static let markMedicationTaken = Notification.Name("markMedicationTaken")
}

@main
struct MedGuardApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var medicationStore = MedicationStore()
    @StateObject private var authStore = AuthStore.shared
    @StateObject private var notificationManager = NotificationManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if authStore.isLoggedIn {
                    MainTabView()
                        .environmentObject(authStore)
                        .environmentObject(medicationStore)
                } else {
                    LoginView()
                        .environmentObject(authStore)
                }
            }
            .task {
                notificationManager.registerNotificationCategories()
            }
        }
    }
}
