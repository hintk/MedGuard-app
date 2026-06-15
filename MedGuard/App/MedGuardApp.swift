import SwiftUI

@main
struct MedGuardApp: App {
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
