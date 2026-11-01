import Foundation

enum TaskStatusTransitionError: LocalizedError {
    case invalidTransition(from: TaskStatus, to: TaskStatus)

    var errorDescription: String? {
        String(localized: "Недопустимый переход между состояниями задачи.")
    }
}

@MainActor
final class SetTaskStatusUseCase {
    private let taskRepository: TaskRepository

    init(taskRepository: TaskRepository) {
        self.taskRepository = taskRepository
    }

    func execute(_ task: TaskItem, status: TaskStatus) throws {
        guard task.status != status else { return }
        guard Self.allowedTransitions[task.status, default: []].contains(status) else {
            throw TaskStatusTransitionError.invalidTransition(from: task.status, to: status)
        }

        let previousStatus = task.status
        let previousCompletedAt = task.completedAt
        task.status = status
        switch status {
        case .active:
            task.completedAt = nil
        case .completed:
            task.completedAt = task.completedAt ?? .now
        case .archived:
            task.completedAt = previousCompletedAt
        }

        do {
            try taskRepository.save()
        } catch {
            task.status = previousStatus
            task.completedAt = previousCompletedAt
            throw error
        }
    }

    private static let allowedTransitions: [TaskStatus: Set<TaskStatus>] = [
        .active: [.completed, .archived],
        .completed: [.active, .archived],
        .archived: [.active]
    ]
}
