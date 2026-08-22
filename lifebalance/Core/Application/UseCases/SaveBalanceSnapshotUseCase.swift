import Foundation

@MainActor
final class SaveBalanceSnapshotUseCase {
    enum ValidationError: LocalizedError {
        case noRatings

        var errorDescription: String? {
            "Оцените хотя бы одну сферу, чтобы сохранить снимок."
        }
    }

    private let balanceRepository: BalanceRepository
    private let userSettingsRepository: UserSettingsRepository

    init(balanceRepository: BalanceRepository, userSettingsRepository: UserSettingsRepository) {
        self.balanceRepository = balanceRepository
        self.userSettingsRepository = userSettingsRepository
    }

    func execute(ratings: [AreaRatingInput], note: String?) throws {
        guard ratings.contains(where: { $0.value != nil }) else {
            throw ValidationError.noRatings
        }
        try balanceRepository.saveSnapshot(ratings: ratings, note: note)
        try userSettingsRepository.updateOnboardingStep(.completed)
    }
}
