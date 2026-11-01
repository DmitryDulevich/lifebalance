import Foundation
import SwiftData

@MainActor
final class SwiftDataGoalRepository: GoalRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchActive() throws -> [Goal] {
        // Filtered in Swift rather than via #Predicate: SwiftData's predicate macro
        // support for enum equality is inconsistent across iOS 17 point releases,
        // and goal counts are small enough that this costs nothing in practice.
        try fetchAll().filter { $0.status == .active }
    }

    func fetchAll() throws -> [Goal] {
        let descriptor = FetchDescriptor<Goal>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func fetchStatusEvents() throws -> [GoalStatusEvent] {
        let descriptor = FetchDescriptor<GoalStatusEvent>(
            sortBy: [SortDescriptor(\.changedAt)]
        )
        return try context.fetch(descriptor)
    }

    func insert(_ goal: Goal, recording event: GoalStatusEvent?) throws {
        context.insert(goal)
        if let event {
            context.insert(event)
        }
        do {
            try context.save()
        } catch {
            if let event {
                context.delete(event)
            }
            context.delete(goal)
            throw error
        }
    }

    func save(recording event: GoalStatusEvent?) throws {
        if let event {
            context.insert(event)
        }
        do {
            try context.save()
        } catch {
            if let event {
                context.delete(event)
            }
            throw error
        }
    }
}
