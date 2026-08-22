import Foundation

struct TaskInput {
    var title: String
    var note: String?
    var dueDate: Date?
    var important: Bool?
    var urgent: Bool?
    var estimateMinutes: Int?
    var lifeArea: LifeArea?
    var goal: Goal?
}

enum TaskValidationError: LocalizedError {
    case emptyTitle

    var errorDescription: String? {
        "Введите название задачи."
    }
}

@MainActor
final class CreateTaskUseCase {
    private let taskRepository: TaskRepository

    init(taskRepository: TaskRepository) {
        self.taskRepository = taskRepository
    }

    @discardableResult
    func execute(_ input: TaskInput) throws -> TaskItem {
        let trimmedTitle = input.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { throw TaskValidationError.emptyTitle }

        let task = TaskItem(
            title: trimmedTitle,
            note: (input.note?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 },
            dueDate: input.dueDate,
            important: input.important,
            urgent: input.urgent,
            estimateMinutes: input.estimateMinutes,
            lifeArea: input.lifeArea,
            goal: input.goal
        )
        try taskRepository.insert(task)
        return task
    }
}
