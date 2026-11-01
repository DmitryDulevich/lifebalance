import Foundation

@MainActor
final class SaveBalanceSnapshotUseCase {
    enum ValidationError: LocalizedError {
        case noRatings
        case valueOutOfRange
        case duplicateArea

        var errorDescription: String? {
            switch self {
            case .noRatings:
                return String(localized: "Оцените хотя бы одну сферу, чтобы сохранить снимок.")
            case .valueOutOfRange:
                return String(localized: "Оценка сферы должна быть от 1 до 10.")
            case .duplicateArea:
                return String(localized: "Одна сфера не может встречаться в снимке несколько раз.")
            }
        }
    }

    private let balanceRepository: BalanceRepository
    private let userSettingsRepository: UserSettingsRepository

    init(balanceRepository: BalanceRepository, userSettingsRepository: UserSettingsRepository) {
        self.balanceRepository = balanceRepository
        self.userSettingsRepository = userSettingsRepository
    }

    func execute(ratings: [AreaRatingInput], note: String?) throws {
        try BalanceRatingsValidator.validate(ratings)
        try balanceRepository.upsertTodaySnapshot(ratings: ratings, note: note)
        try userSettingsRepository.updateOnboardingStep(.completed)
    }
}

enum BalanceRatingsValidator {
    static func validate(_ ratings: [AreaRatingInput]) throws {
        guard ratings.contains(where: { $0.value != nil }) else {
            throw SaveBalanceSnapshotUseCase.ValidationError.noRatings
        }
        guard ratings.allSatisfy({ input in
            input.value.map { (1...10).contains($0) } ?? true
        }) else {
            throw SaveBalanceSnapshotUseCase.ValidationError.valueOutOfRange
        }
        let areaIDs = ratings.map { $0.area.id }
        guard Set(areaIDs).count == areaIDs.count else {
            throw SaveBalanceSnapshotUseCase.ValidationError.duplicateArea
        }
    }
}
