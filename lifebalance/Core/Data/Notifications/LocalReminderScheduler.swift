import Foundation
import UserNotifications

@MainActor
final class LocalReminderScheduler: ReminderScheduling {
    private enum Identifier {
        static let taskPrefix = "task-reminder."
        static let habits = "habit-reminder.daily"
        static let weeklyReview = "weekly-review-reminder"
    }

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    func authorizationState() async -> ReminderAuthorizationState {
        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined: .notDetermined
        case .authorized, .provisional, .ephemeral: .authorized
        case .denied: .denied
        @unknown default: .denied
        }
    }

    func refresh(
        tasks: [TaskItem],
        hasActiveHabits: Bool,
        preferences: ReminderPreferences,
        now: Date = .now
    ) async throws {
        let pending = await center.pendingNotificationRequests()
        let managedIDs = pending.map(\.identifier).filter {
            $0.hasPrefix(Identifier.taskPrefix)
                || $0 == Identifier.habits
                || $0 == Identifier.weeklyReview
        }
        center.removePendingNotificationRequests(withIdentifiers: managedIDs)

        guard await authorizationState() == .authorized else { return }

        if preferences.taskRemindersEnabled {
            let upcoming = tasks
                .filter { $0.status == .active && $0.dueDate != nil }
                .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
                .prefix(48)

            for task in upcoming {
                guard let dueDate = task.dueDate else { continue }
                let reminderDate = dueDate.addingTimeInterval(-Double(preferences.taskLeadMinutes * 60))
                guard reminderDate > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = String(localized: "Скоро срок задачи")
                content.body = String(localized: "Откройте «Баланс», чтобы проверить запланированную задачу.")
                content.sound = .default
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: Calendar.current.dateComponents(
                        [.year, .month, .day, .hour, .minute],
                        from: reminderDate
                    ),
                    repeats: false
                )
                try await center.add(UNNotificationRequest(
                    identifier: Identifier.taskPrefix + task.id.uuidString,
                    content: content,
                    trigger: trigger
                ))
            }
        }

        if preferences.habitRemindersEnabled && hasActiveHabits {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "Время для привычек")
            content.body = String(localized: "Отметьте сегодняшние привычки и сохраните ритм.")
            content.sound = .default
            try await center.add(UNNotificationRequest(
                identifier: Identifier.habits,
                content: content,
                trigger: dailyTrigger(minutes: preferences.habitReminderMinutes)
            ))
        }

        if preferences.weeklyReviewEnabled {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "Время подвести итоги недели")
            content.body = String(localized: "Посмотрите результаты и выберите приоритеты следующей недели.")
            content.sound = .default
            var components = timeComponents(minutes: preferences.weeklyReviewMinutes)
            components.weekday = min(7, max(1, preferences.weeklyReviewWeekday))
            try await center.add(UNNotificationRequest(
                identifier: Identifier.weeklyReview,
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            ))
        }
    }

    private func dailyTrigger(minutes: Int) -> UNCalendarNotificationTrigger {
        UNCalendarNotificationTrigger(dateMatching: timeComponents(minutes: minutes), repeats: true)
    }

    private func timeComponents(minutes: Int) -> DateComponents {
        DateComponents(hour: min(23, max(0, minutes / 60)), minute: min(59, max(0, minutes % 60)))
    }
}
