import Foundation

@MainActor
final class ToggleTaskCompletionUseCase {
    private let taskRepository: TaskRepository

    init(taskRepository: TaskRepository) {
        self.taskRepository = taskRepository
    }

    func execute(_ task: TaskItem) throws {
        if task.status == .completed {
            task.status = .active
            task.completedAt = nil
        } else {
            task.status = .completed
            task.completedAt = .now
        }
        try taskRepository.save()
    }
}
