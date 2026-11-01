import Foundation
import UserNotifications

@MainActor
final class LocalFocusNotificationScheduler: FocusNotificationScheduling {
    private let center: UNUserNotificationCenter
    private var schedulingTask: Task<Void, Never>?

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func scheduleCompletion(
        sessionID: UUID,
        taskTitle _: String?,
        after timeInterval: TimeInterval
    ) {
        cancelCompletion(sessionID: sessionID)
        guard timeInterval > 0 else { return }

        schedulingTask = Task { [center] in
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound])
                guard granted, !Task.isCancelled else { return }

                let content = UNMutableNotificationContent()
                content.title = String(localized: "Фокус-сессия завершена")
                content.body = String(localized: "Запланированное время фокусировки закончилось.")
                content.sound = .default

                let trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: max(1, timeInterval),
                    repeats: false
                )
                let request = UNNotificationRequest(
                    identifier: Self.identifier(for: sessionID),
                    content: content,
                    trigger: trigger
                )
                try await center.add(request)
            } catch {
                guard !Task.isCancelled else { return }
                AppLogger.error(error, context: "focus.notification.schedule")
            }
        }
    }

    func cancelCompletion(sessionID: UUID) {
        schedulingTask?.cancel()
        schedulingTask = nil
        let identifiers = [Self.identifier(for: sessionID)]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    private static func identifier(for sessionID: UUID) -> String {
        "focus-session.\(sessionID.uuidString)"
    }
}
