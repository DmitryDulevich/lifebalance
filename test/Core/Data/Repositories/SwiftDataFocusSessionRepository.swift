import Foundation
import SwiftData

@MainActor
final class SwiftDataFocusSessionRepository: FocusSessionRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchActiveSession() throws -> FocusSession? {
        // Filtered in Swift rather than via #Predicate — see note in SwiftDataGoalRepository.
        let descriptor = FetchDescriptor<FocusSession>(sortBy: [SortDescriptor(\.startAt, order: .reverse)])
        return try context.fetch(descriptor).first { $0.status == .running || $0.status == .paused }
    }

    func fetchAll() throws -> [FocusSession] {
        let descriptor = FetchDescriptor<FocusSession>(sortBy: [SortDescriptor(\.startAt, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func insert(_ session: FocusSession) throws {
        context.insert(session)
        try context.save()
    }

    func save() throws {
        try context.save()
    }
}
