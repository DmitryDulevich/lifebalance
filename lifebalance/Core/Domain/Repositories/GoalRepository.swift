import Foundation

@MainActor
protocol GoalRepository {
    func fetchActive() throws -> [Goal]
    func fetchAll() throws -> [Goal]
    func fetchStatusEvents() throws -> [GoalStatusEvent]
    func insert(_ goal: Goal, recording event: GoalStatusEvent?) throws
    func save(recording event: GoalStatusEvent?) throws
}

extension GoalRepository {
    func insert(_ goal: Goal) throws {
        try insert(
            goal,
            recording: GoalStatusEvent(
                goalID: goal.id,
                goalTitleSnapshot: goal.title,
                status: goal.status,
                changedAt: goal.createdAt
            )
        )
    }

    func save() throws {
        try save(recording: nil)
    }
}
