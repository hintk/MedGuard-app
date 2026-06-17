import Foundation
import UserNotifications
import UIKit

@MainActor
final class NotificationManager: ObservableObject {
    @Published var isAuthorized: Bool = false

    static let shared = NotificationManager()

    private init() {
        Task { await checkAuthorization() }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            await MainActor.run { self.isAuthorized = granted }
            return granted
        } catch {
            return false
        }
    }

    func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run { self.isAuthorized = settings.authorizationStatus == .authorized }
    }

    func scheduleMedicationReminder(
        medicationName: String,
        time: Date,
        medicationId: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = "用药提醒"
        content.body = "该服用「\(medicationName)」了"
        content.sound = .default
        content.userInfo = ["medicationId": medicationId, "type": "reminder"]
        content.categoryIdentifier = "MEDICATION_REMINDER"

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "medication_reminder_\(medicationId)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelMedicationReminder(medicationId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["medication_reminder_\(medicationId)"]
        )
    }

    func sendLocalNotification(
        title: String,
        body: String,
        type: NotificationRecord.NotificationType,
        medicationName: String? = nil,
        recipientUserId: String
    ) {
        let record = NotificationRecord(
            type: type,
            title: title,
            body: body,
            medicationName: medicationName,
            recipientUserId: recipientUserId
        )
        AuthStore.shared.addNotificationRecord(record)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["type": type.rawValue]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func registerNotificationCategories() {
        let takenAction = UNNotificationAction(
            identifier: "MARK_TAKEN",
            title: "已服用",
            options: []
        )
        let callAction = UNNotificationAction(
            identifier: "CALL_CHILD",
            title: "打电话叮嘱",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: "MEDICATION_REMINDER",
            actions: [takenAction, callAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
