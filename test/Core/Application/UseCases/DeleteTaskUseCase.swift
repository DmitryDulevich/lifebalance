import Foundation

@MainActor
final class DeleteTaskUseCase {
    private let taskRepository: TaskRepository

    init(taskRepository: TaskRepository) {
        self.taskRepository = taskRepository
    }

    func execute(_ task: TaskItem) throws {
        try taskRepository.delete(task)
    }
}
