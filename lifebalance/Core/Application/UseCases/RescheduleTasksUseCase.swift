import Foundation

enum TaskRescheduleError: LocalizedError {
    case inactiveTask

    var errorDescription: String? {
        String(localized: "Переносить можно только активные задачи.")
    }
}

@MainActor
final class RescheduleTasksUseCase {
    private let taskRepository: TaskRepository

    init(taskRepository: TaskRepository) {
        self.taskRepository = taskRepository
    }

    func moveToTomorrow(
        _ tasks: [TaskItem],
        now: Date = .now,
        calendar: Calendar = .current
    ) throws {
        guard tasks.allSatisfy({ $0.status == .active }) else {
            throw TaskRescheduleError.inactiveTask
        }
        guard !tasks.isEmpty else { return }

        let previousDates = tasks.map { ($0, $0.dueDate) }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now

        for task in tasks {
            let source = task.dueDate ?? now
            let time = calendar.dateComponents([.hour, .minute], from: source)
            task.dueDate = calendar.date(
                bySettingHour: time.hour ?? 9,
                minute: time.minute ?? 0,
                second: 0,
                of: tomorrow
            ) ?? tomorrow
        }

        do {
            try taskRepository.save()
        } catch {
            for (task, dueDate) in previousDates {
                task.dueDate = dueDate
            }
            throw error
        }
    }
}
