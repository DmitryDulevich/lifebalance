import Foundation

@MainActor
final class GenerateRecurringTasksUseCase {
    private let repository: RecurringTaskRepository

    init(repository: RecurringTaskRepository) {
        self.repository = repository
    }

    @discardableResult
    func execute(now: Date = .now, calendar: Calendar = .current) throws -> Int {
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        var generatedCount = 0

        for template in try repository.fetchActive() where template.nextDueDate < endOfToday {
            var dueDate = template.nextDueDate
            var tasks: [TaskItem] = []

            // The cap prevents a corrupt or very old schedule from blocking app launch.
            while dueDate < endOfToday && tasks.count < 100 {
                tasks.append(TaskItem(
                    title: template.title,
                    note: template.taskNote,
                    dueDate: dueDate,
                    important: template.important,
                    urgent: template.urgent,
                    estimateMinutes: template.estimateMinutes,
                    lifeArea: template.lifeArea,
                    goal: template.goal
                ))
                dueDate = RecurrenceCalculator.nextDate(
                    after: dueDate,
                    frequency: template.frequency,
                    interval: template.recurrenceInterval,
                    calendar: calendar
                )
            }

            if !tasks.isEmpty {
                try repository.insertGeneratedTasks(tasks, advancing: template, to: dueDate)
                generatedCount += tasks.count
            }
        }
        return generatedCount
    }
}
