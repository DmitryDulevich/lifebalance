import Foundation
import SwiftData

@MainActor
final class SwiftDataRecurringTaskRepository: RecurringTaskRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [RecurringTask] {
        let descriptor = FetchDescriptor<RecurringTask>(sortBy: [SortDescriptor(\.createdAt)])
        return try context.fetch(descriptor)
    }

    func fetchActive() throws -> [RecurringTask] {
        let descriptor = FetchDescriptor<RecurringTask>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.nextDueDate)]
        )
        return try context.fetch(descriptor)
    }

    func insert(_ recurringTask: RecurringTask) throws {
        context.insert(recurringTask)
        try context.save()
    }

    func insertGeneratedTasks(
        _ tasks: [TaskItem],
        advancing recurringTask: RecurringTask,
        to nextDate: Date
    ) throws {
        let previousDate = recurringTask.nextDueDate
        tasks.forEach(context.insert)
        recurringTask.nextDueDate = nextDate
        do {
            try context.save()
        } catch {
            recurringTask.nextDueDate = previousDate
            tasks.forEach(context.delete)
            throw error
        }
    }

    func save() throws {
        try context.save()
    }
}
