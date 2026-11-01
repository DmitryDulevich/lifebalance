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
    case titleTooLong
    case invalidEstimate

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return String(localized: "Введите название задачи.")
        case .titleTooLong:
            return String(localized: "Название задачи не должно превышать 120 символов.")
        case .invalidEstimate:
            return String(localized: "Оценка времени должна быть от 1 минуты до 24 часов.")
        }
    }
}

enum TaskInputValidator {
    static let maximumTitleLength = 120
    static let validEstimateMinutes = 1...1_440

    static func validateAndNormalize(_ input: TaskInput) throws -> TaskInput {
        var normalized = input
        normalized.title = input.title.trimmingCharacters(in: .whitespacesAndNewlines)
        normalized.note = input.note?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty

        guard !normalized.title.isEmpty else { throw TaskValidationError.emptyTitle }
        guard normalized.title.count <= maximumTitleLength else { throw TaskValidationError.titleTooLong }
        if let estimate = normalized.estimateMinutes {
            guard validEstimateMinutes.contains(estimate) else { throw TaskValidationError.invalidEstimate }
        }
        return normalized
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

@MainActor
final class CreateTaskUseCase {
    private let taskRepository: TaskRepository

    init(taskRepository: TaskRepository) {
        self.taskRepository = taskRepository
    }

    @discardableResult
    func execute(_ input: TaskInput) throws -> TaskItem {
        let input = try TaskInputValidator.validateAndNormalize(input)

        let task = TaskItem(
            title: input.title,
            note: input.note,
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
