import Foundation
import Testing
@testable import lifebalance

@Suite("Reschedule tasks")
@MainActor
struct RescheduleTasksUseCaseTests {
    @Test("Moves active tasks to tomorrow and preserves time")
    func movesTasksToTomorrow() throws {
        let repository = FakeTaskRepository()
        let useCase = RescheduleTasksUseCase(taskRepository: repository)
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 12))!
        let oldDate = calendar.date(from: DateComponents(year: 2026, month: 10, day: 30, hour: 16, minute: 45))!
        let task = TaskItem(title: "Просрочено", dueDate: oldDate)

        try useCase.moveToTomorrow([task], now: now, calendar: calendar)

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: task.dueDate!)
        #expect(components == DateComponents(year: 2026, month: 11, day: 2, hour: 16, minute: 45))
        #expect(repository.saveCallCount == 1)
    }

    @Test("Restores every date when batch save fails")
    func rollsBackBatchOnFailure() {
        let repository = FakeTaskRepository()
        repository.saveError = FakeRepositoryError.forcedFailure
        let firstDate = Date.now.addingTimeInterval(-86_400)
        let secondDate = Date.now.addingTimeInterval(-172_800)
        let first = TaskItem(title: "One", dueDate: firstDate)
        let second = TaskItem(title: "Two", dueDate: secondDate)
        let useCase = RescheduleTasksUseCase(taskRepository: repository)

        #expect(throws: FakeRepositoryError.self) {
            try useCase.moveToTomorrow([first, second])
        }
        #expect(first.dueDate == firstDate)
        #expect(second.dueDate == secondDate)
    }

    @Test("Rejects inactive tasks")
    func rejectsInactiveTasks() {
        let repository = FakeTaskRepository()
        let useCase = RescheduleTasksUseCase(taskRepository: repository)
        let completed = TaskItem(title: "Done", status: .completed)

        #expect(throws: TaskRescheduleError.self) {
            try useCase.moveToTomorrow([completed])
        }
        #expect(repository.saveCallCount == 0)
    }
}
