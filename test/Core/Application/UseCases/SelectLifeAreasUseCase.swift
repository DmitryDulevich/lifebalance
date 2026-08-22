import Foundation

struct LifeAreaDraft {
    let name: String
    let icon: String
    let colorHex: String
}

@MainActor
final class SelectLifeAreasUseCase {
    enum ValidationError: LocalizedError {
        case tooFew
        case tooMany

        var errorDescription: String? {
            switch self {
            case .tooFew:
                return "Выберите минимум 3 сферы."
            case .tooMany:
                return "Можно выбрать не более 8 сфер."
            }
        }
    }

    private let lifeAreaRepository: LifeAreaRepository
    private let userSettingsRepository: UserSettingsRepository

    init(lifeAreaRepository: LifeAreaRepository, userSettingsRepository: UserSettingsRepository) {
        self.lifeAreaRepository = lifeAreaRepository
        self.userSettingsRepository = userSettingsRepository
    }

    func execute(_ drafts: [LifeAreaDraft]) throws {
        guard drafts.count >= 3 else { throw ValidationError.tooFew }
        guard drafts.count <= 8 else { throw ValidationError.tooMany }

        let areas = drafts.enumerated().map { index, draft in
            LifeArea(name: draft.name, icon: draft.icon, colorHex: draft.colorHex, order: index)
        }
        try lifeAreaRepository.insert(areas)
        try userSettingsRepository.updateOnboardingStep(.initialBalance)
    }
}
