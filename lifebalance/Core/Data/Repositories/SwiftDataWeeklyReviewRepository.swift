import Foundation
import SwiftData

@MainActor
final class SwiftDataWeeklyReviewRepository: WeeklyReviewRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [WeeklyReview] {
        let descriptor = FetchDescriptor<WeeklyReview>(sortBy: [SortDescriptor(\.weekStart, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func upsert(_ review: WeeklyReview) throws {
        let start = review.weekStart
        let descriptor = FetchDescriptor<WeeklyReview>(predicate: #Predicate { $0.weekStart == start })
        if let existing = try context.fetch(descriptor).first {
            existing.completedAt = review.completedAt
            existing.completedTaskCount = review.completedTaskCount
            existing.focusMinutes = review.focusMinutes
            existing.habitCheckInCount = review.habitCheckInCount
            existing.balanceAverage = review.balanceAverage
            existing.note = review.note
            existing.priorities = review.priorities
        } else {
            context.insert(review)
        }
        try context.save()
    }
}
