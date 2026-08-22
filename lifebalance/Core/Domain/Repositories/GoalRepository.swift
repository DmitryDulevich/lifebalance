import Foundation

@MainActor
protocol GoalRepository {
    func fetchActive() throws -> [Goal]
    func insert(_ goal: Goal) throws
    func save() throws
}
