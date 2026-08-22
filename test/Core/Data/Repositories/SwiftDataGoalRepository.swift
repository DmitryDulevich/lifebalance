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
        let descriptor = FetchDescriptor<Goal>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try context.fetch(descriptor).filter { $0.status == .active }
    }

    func insert(_ goal: Goal) throws {
        context.insert(goal)
        try context.save()
    }

    func save() throws {
        try context.save()
    }
}
