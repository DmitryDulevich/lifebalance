import Foundation

@MainActor
protocol RecurringTaskRepository {
    func fetchAll() throws -> [RecurringTask]
    func fetchActive() throws -> [RecurringTask]
    func insert(_ recurringTask: RecurringTask) throws
    func insertGeneratedTasks(_ tasks: [TaskItem], advancing recurringTask: RecurringTask, to nextDate: Date) throws
    func save() throws
}
