import Foundation

@MainActor
protocol TaskRepository {
    func fetchAll() throws -> [TaskItem]
    func insert(_ task: TaskItem) throws
    func delete(_ task: TaskItem) throws
    func save() throws
}
