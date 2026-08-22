import Foundation

@MainActor
protocol FocusSessionRepository {
    func fetchActiveSession() throws -> FocusSession?
    func fetchAll() throws -> [FocusSession]
    func insert(_ session: FocusSession) throws
    func save() throws
}
