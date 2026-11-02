import Foundation

@MainActor
protocol WeeklyReviewRepository {
    func fetchAll() throws -> [WeeklyReview]
    func upsert(_ review: WeeklyReview) throws
}
