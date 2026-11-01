import Foundation

@MainActor
final class ToggleTaskCompletionUseCase {
    private let taskRepository: TaskRepository

    init(taskRepository: TaskRepository) {
        self.taskRepository = taskRepository
    }

    func execute(_ task: TaskItem) throws {
        guard task.status != .archived else {
            throw TaskStatusTransitionError.invalidTransition(from: .archived, to: .completed)
        }
        let previousStatus = task.status
        let previousCompletedAt = task.completedAt

        if task.status == .completed {
            task.status = .active
            task.completedAt = nil
        } else {
            task.status = .completed
            task.completedAt = .now
        }
        do {
            try taskRepository.save()
        } catch {
            task.status = previousStatus
            task.completedAt = previousCompletedAt
            throw error
        }
    }
}
