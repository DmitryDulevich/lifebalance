import Foundation

enum ReminderAuthorizationState: Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
}

struct ReminderPreferences: Codable, Equatable, Sendable {
    var taskRemindersEnabled = false
    var taskLeadMinutes = 60
    var habitRemindersEnabled = false
    var habitReminderMinutes = 20 * 60
    var weeklyReviewEnabled = false
    var weeklyReviewWeekday = 1
    var weeklyReviewMinutes = 18 * 60
}

@MainActor
protocol ReminderScheduling: AnyObject {
    func requestAuthorization() async throws -> Bool
    func authorizationState() async -> ReminderAuthorizationState
    func refresh(
        tasks: [TaskItem],
        hasActiveHabits: Bool,
        preferences: ReminderPreferences,
        now: Date
    ) async throws
}

@MainActor
final class NoopReminderScheduler: ReminderScheduling {
    func requestAuthorization() async throws -> Bool { true }
    func authorizationState() async -> ReminderAuthorizationState { .authorized }
    func refresh(
        tasks: [TaskItem],
        hasActiveHabits: Bool,
        preferences: ReminderPreferences,
        now: Date
    ) async throws {}
}
