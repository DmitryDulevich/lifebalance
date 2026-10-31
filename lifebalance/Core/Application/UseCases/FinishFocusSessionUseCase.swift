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
        let previousStatus = session.status
        let previousEndAt = session.endAt
        let previousPausedSeconds = session.pausedSeconds
        let previousPausedAt = session.pausedAt

        if session.status == .paused, let pausedAt = session.pausedAt {
            session.pausedSeconds += max(0, Int(endedAt.timeIntervalSince(pausedAt).rounded()))
        }
        session.pausedAt = nil
        session.status = cancelled ? .cancelled : .completed
        session.endAt = endedAt
        do {
            try focusSessionRepository.save()
        } catch {
            session.status = previousStatus
            session.endAt = previousEndAt
            session.pausedSeconds = previousPausedSeconds
            session.pausedAt = previousPausedAt
            throw error
        }

        if completeTask, let task = session.task, task.status != .completed {
            let previousTaskStatus = task.status
            let previousCompletedAt = task.completedAt
            task.status = .completed
            task.completedAt = endedAt
            do {
                try taskRepository.save()
            } catch {
                task.status = previousTaskStatus
                task.completedAt = previousCompletedAt
                throw error
            }
        }
    }
}
