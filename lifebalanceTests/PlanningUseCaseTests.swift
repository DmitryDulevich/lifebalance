import Foundation
import Testing
@testable import lifebalance

@Suite("Planning")
@MainActor
struct PlanningUseCaseTests {
    @Test("Weekday recurrence skips a weekend")
    func weekdayRecurrenceSkipsWeekend() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let friday = calendar.date(from: DateComponents(year: 2026, month: 11, day: 6, hour: 9))!

        let next = RecurrenceCalculator.nextDate(
            after: friday,
            frequency: .weekdays,
            calendar: calendar
        )

        #expect(calendar.component(.weekday, from: next) == 2)
        #expect(calendar.component(.day, from: next) == 9)
    }

    @Test("Generator creates missed occurrences once and advances the template")
    func generatesOccurrences() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let first = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 9))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 12))!
        let template = RecurringTask(
            sourceTaskID: UUID(),
            title: "Вода",
            frequency: .daily,
            nextDueDate: first
        )
        let repository = FakeRecurringTaskRepository(template: template)
        let useCase = GenerateRecurringTasksUseCase(repository: repository)

        let generated = try useCase.execute(now: now, calendar: calendar)
        let secondRun = try useCase.execute(now: now, calendar: calendar)

        #expect(generated == 2)
        #expect(secondRun == 0)
        #expect(repository.generatedTasks.map(\.title) == ["Вода", "Вода"])
        #expect(template.nextDueDate > now)
    }
}

@MainActor
private final class FakeRecurringTaskRepository: RecurringTaskRepository {
    let template: RecurringTask
    var generatedTasks: [TaskItem] = []

    init(template: RecurringTask) {
        self.template = template
    }

    func fetchAll() throws -> [RecurringTask] { [template] }

    func fetchActive() throws -> [RecurringTask] {
        template.isActive ? [template] : []
    }

    func insert(_ recurringTask: RecurringTask) throws {}

    func insertGeneratedTasks(
        _ tasks: [TaskItem],
        advancing recurringTask: RecurringTask,
        to nextDate: Date
    ) throws {
        generatedTasks.append(contentsOf: tasks)
        recurringTask.nextDueDate = nextDate
    }

    func save() throws {}
}
