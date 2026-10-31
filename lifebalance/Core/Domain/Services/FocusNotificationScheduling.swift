import Foundation

@MainActor
protocol FocusNotificationScheduling: AnyObject {
    func scheduleCompletion(
        sessionID: UUID,
        taskTitle: String?,
        after timeInterval: TimeInterval
    )
    func cancelCompletion(sessionID: UUID)
}

@MainActor
final class NoopFocusNotificationScheduler: FocusNotificationScheduling {
    func scheduleCompletion(sessionID: UUID, taskTitle: String?, after timeInterval: TimeInterval) {}
    func cancelCompletion(sessionID: UUID) {}
}
