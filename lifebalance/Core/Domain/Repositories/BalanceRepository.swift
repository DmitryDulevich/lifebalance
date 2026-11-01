import Foundation

struct AreaRatingInput {
    let area: LifeArea
    let value: Int?
    let note: String?
}

@MainActor
protocol BalanceRepository {
    func saveSnapshot(ratings: [AreaRatingInput], note: String?) throws
    func fetchLatestSnapshot() throws -> BalanceSnapshot?
    func fetchAllSnapshots() throws -> [BalanceSnapshot]
    /// Updates today's snapshot in place if one already exists, otherwise creates one.
    /// Used by the Balance tab's steppers so repeated small adjustments don't spawn a
    /// new snapshot row per tap.
    func upsertTodaySnapshot(ratings: [AreaRatingInput], note: String?) throws
}
