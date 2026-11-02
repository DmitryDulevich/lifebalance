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
    var recurrence: TaskRecurrenceInput? = nil
}

enum TaskValidationError: LocalizedError {
    case emptyTitle
    case titleTooLong
    case invalidEstimate
    case recurrenceRequiresDate

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return String(localized: "Введите название задачи.")
        case .titleTooLong:
            return String(localized: "Название задачи не должно превышать 120 символов.")
        case .invalidEstimate:
            return String(localized: "Оценка времени должна быть от 1 минуты до 24 часов.")
        case .recurrenceRequiresDate:
            return String(localized: "Для повторяющейся задачи укажите дату первого выполнения.")
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
        if normalized.recurrence != nil, normalized.dueDate == nil {
            throw TaskValidationError.recurrenceRequiresDate
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
    private let recurringTaskRepository: RecurringTaskRepository?

    init(taskRepository: TaskRepository, recurringTaskRepository: RecurringTaskRepository? = nil) {
        self.taskRepository = taskRepository
        self.recurringTaskRepository = recurringTaskRepository
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

        if let recurrence = input.recurrence,
           let firstDate = input.dueDate,
           let recurringTaskRepository {
            let template = RecurringTask(
                sourceTaskID: task.id,
                title: input.title,
                taskNote: input.note,
                frequency: recurrence.frequency,
                recurrenceInterval: recurrence.interval,
                nextDueDate: RecurrenceCalculator.nextDate(
                    after: firstDate,
                    frequency: recurrence.frequency,
                    interval: recurrence.interval
                ),
                important: input.important,
                urgent: input.urgent,
                estimateMinutes: input.estimateMinutes,
                lifeArea: input.lifeArea,
                goal: input.goal
            )
            do {
                try recurringTaskRepository.insert(template)
            } catch {
                try? taskRepository.delete(task)
                throw error
            }
        }
        return task
    }
}
