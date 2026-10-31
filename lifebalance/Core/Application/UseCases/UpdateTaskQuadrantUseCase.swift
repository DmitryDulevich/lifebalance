import Foundation

/// Sets a task's important/urgent flags — used by both matrix drag-and-drop
/// and the accessible "change quadrant" menu fallback.
@MainActor
final class UpdateTaskQuadrantUseCase {
    private let taskRepository: TaskRepository

    init(taskRepository: TaskRepository) {
        self.taskRepository = taskRepository
    }

    func execute(_ task: TaskItem, important: Bool?, urgent: Bool?) throws {
        let previousImportant = task.important
        let previousUrgent = task.urgent
        task.important = important
        task.urgent = urgent
        do {
            try taskRepository.save()
        } catch {
            task.important = previousImportant
            task.urgent = previousUrgent
            throw error
        }
    }
}
