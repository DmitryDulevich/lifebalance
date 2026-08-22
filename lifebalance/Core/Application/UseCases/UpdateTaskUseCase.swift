import Foundation

@MainActor
final class UpdateTaskUseCase {
    private let taskRepository: TaskRepository

    init(taskRepository: TaskRepository) {
        self.taskRepository = taskRepository
    }

    func execute(_ task: TaskItem, with input: TaskInput) throws {
        let trimmedTitle = input.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { throw TaskValidationError.emptyTitle }

        task.title = trimmedTitle
        task.note = (input.note?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
        task.dueDate = input.dueDate
        task.important = input.important
        task.urgent = input.urgent
        task.estimateMinutes = input.estimateMinutes
        task.lifeArea = input.lifeArea
        task.goal = input.goal
        try taskRepository.save()
    }
}
