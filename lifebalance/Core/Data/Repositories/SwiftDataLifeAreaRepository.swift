import Foundation
import SwiftData

@MainActor
final class SwiftDataLifeAreaRepository: LifeAreaRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchActiveAreas() throws -> [LifeArea] {
        let descriptor = FetchDescriptor<LifeArea>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.order)]
        )
        return try context.fetch(descriptor)
    }

    func fetchAllAreas() throws -> [LifeArea] {
        let descriptor = FetchDescriptor<LifeArea>(sortBy: [SortDescriptor(\.order)])
        return try context.fetch(descriptor)
    }

    func insert(_ areas: [LifeArea]) throws {
        for area in areas {
            context.insert(area)
        }
        try context.save()
    }

    func save() throws {
        try context.save()
    }
}
