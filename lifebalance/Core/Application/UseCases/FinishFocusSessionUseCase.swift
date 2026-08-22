import Foundation

@MainActor
final class FinishFocusSessionUseCase {
    private let focusSessionRepository: FocusSessionRepository
    private let taskRepository: TaskRepository

    init(focusSessionRepository: FocusSessionRepository, taskRepository: TaskRepository) {
        self.focusSessionRepository = focusSessionRepository
        self.taskRepository = taskRepository
    }

    func execute(
        _ session: FocusSession,
        completeTask: Bool,
        cancelled: Bool = false,
        endedAt: Date = .now
    ) throws {
        if session.status == .paused, let pausedAt = session.pausedAt {
            session.pausedSeconds += max(0, Int(endedAt.timeIntervalSince(pausedAt).rounded()))
        }
        session.pausedAt = nil
        session.status = cancelled ? .cancelled : .completed
        session.endAt = endedAt
        try focusSessionRepository.save()

        if completeTask, let task = session.task, task.status != .completed {
            task.status = .completed
            task.completedAt = endedAt
            try taskRepository.save()
        }
    }
}
