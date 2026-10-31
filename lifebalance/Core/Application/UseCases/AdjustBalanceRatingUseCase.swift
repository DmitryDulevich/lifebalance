import Foundation

@MainActor
final class AdjustBalanceRatingUseCase {
    private let balanceRepository: BalanceRepository

    init(balanceRepository: BalanceRepository) {
        self.balanceRepository = balanceRepository
    }

    func execute(ratings: [AreaRatingInput]) throws {
        try BalanceRatingsValidator.validate(ratings)
        try balanceRepository.upsertTodaySnapshot(ratings: ratings, note: nil)
    }
}
