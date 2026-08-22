import Foundation

@MainActor
final class FinishFocusSessionUseCase {
    private let focusSessionRepository: FocusSessionRepository
    private let taskRepository: TaskRepository

    init(focusSessionRepository: FocusSessionRepository, taskRepository: TaskRepository) {
        self.focusSessionRepository = focusSessionRepository
        self.taskRepository = taskRepository
    }

    func execute(_ session: FocusSession, completeTask: Bool, cancelled: Bool = false) throws {
        session.status = cancelled ? .cancelled : .completed
        session.endAt = .now
        try focusSessionRepository.save()

        if completeTask, let task = session.task, task.status != .completed {
            task.status = .completed
            task.completedAt = .now
            try taskRepository.save()
        }
    }
}
