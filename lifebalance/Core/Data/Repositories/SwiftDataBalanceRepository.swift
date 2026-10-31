import Foundation
import SwiftData

@MainActor
final class SwiftDataBalanceRepository: BalanceRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func saveSnapshot(ratings: [AreaRatingInput], note: String?) throws {
        let snapshot = BalanceSnapshot(note: note)
        context.insert(snapshot)
        for input in ratings {
            let rating = BalanceRating(
                value: input.value,
                note: input.note,
                area: input.area,
                snapshot: snapshot
            )
            context.insert(rating)
        }
        try context.save()
    }

    func fetchLatestSnapshot() throws -> BalanceSnapshot? {
        var descriptor = FetchDescriptor<BalanceSnapshot>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func upsertTodaySnapshot(ratings: [AreaRatingInput], note: String?) throws {
        let latest = try fetchLatestSnapshot()

        if let latest, Calendar.current.isDateInToday(latest.createdAt) {
            if let note {
                latest.note = note
            }
            for rating in latest.ratings {
                context.delete(rating)
            }
            latest.ratings = []
            for input in ratings {
                let rating = BalanceRating(value: input.value, note: input.note, area: input.area, snapshot: latest)
                context.insert(rating)
            }
        } else {
            let snapshot = BalanceSnapshot(note: note)
            context.insert(snapshot)
            for input in ratings {
                let rating = BalanceRating(value: input.value, note: input.note, area: input.area, snapshot: snapshot)
                context.insert(rating)
            }
        }
        try context.save()
    }
}
