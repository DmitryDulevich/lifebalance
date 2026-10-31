import Foundation

@MainActor
final class UpdateTaskUseCase {
    private let taskRepository: TaskRepository

    init(taskRepository: TaskRepository) {
        self.taskRepository = taskRepository
    }

    func execute(_ task: TaskItem, with input: TaskInput) throws {
        let input = try TaskInputValidator.validateAndNormalize(input)
        let previous = TaskValues(task)

        task.title = input.title
        task.note = input.note
        task.dueDate = input.dueDate
        task.important = input.important
        task.urgent = input.urgent
        task.estimateMinutes = input.estimateMinutes
        task.lifeArea = input.lifeArea
        task.goal = input.goal
        do {
            try taskRepository.save()
        } catch {
            previous.restore(on: task)
            throw error
        }
    }
}

private struct TaskValues {
    let title: String
    let note: String?
    let dueDate: Date?
    let important: Bool?
    let urgent: Bool?
    let estimateMinutes: Int?
    let lifeArea: LifeArea?
    let goal: Goal?

    init(_ task: TaskItem) {
        title = task.title
        note = task.note
        dueDate = task.dueDate
        important = task.important
        urgent = task.urgent
        estimateMinutes = task.estimateMinutes
        lifeArea = task.lifeArea
        goal = task.goal
    }

    func restore(on task: TaskItem) {
        task.title = title
        task.note = note
        task.dueDate = dueDate
        task.important = important
        task.urgent = urgent
        task.estimateMinutes = estimateMinutes
        task.lifeArea = lifeArea
        task.goal = goal
    }
}
