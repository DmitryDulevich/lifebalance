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
        case invalidName
        case duplicateName
        case conflictsWithSavedSelection

        var errorDescription: String? {
            switch self {
            case .tooFew:
                return String(localized: "Выберите минимум 3 сферы.")
            case .tooMany:
                return String(localized: "Можно выбрать не более 8 сфер.")
            case .invalidName:
                return String(localized: "Название сферы должно содержать от 1 до 30 символов.")
            case .duplicateName:
                return String(localized: "Названия выбранных сфер не должны повторяться.")
            case .conflictsWithSavedSelection:
                return String(localized: "В приложении уже сохранён другой набор сфер.")
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

        let normalizedDrafts = drafts.map { draft in
            LifeAreaDraft(
                name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
                icon: draft.icon,
                colorHex: draft.colorHex
            )
        }
        guard normalizedDrafts.allSatisfy({ (1...30).contains($0.name.count) }) else {
            throw ValidationError.invalidName
        }
        let normalizedNames = normalizedDrafts.map {
            $0.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        }
        guard Set(normalizedNames).count == normalizedNames.count else {
            throw ValidationError.duplicateName
        }

        let existingAreas = try lifeAreaRepository.fetchActiveAreas()
        if !existingAreas.isEmpty {
            let existingNames = existingAreas.map(\.name)
            let requestedNames = normalizedDrafts.map(\.name)
            guard existingNames == requestedNames else {
                throw ValidationError.conflictsWithSavedSelection
            }
            try userSettingsRepository.updateOnboardingStep(.initialBalance)
            return
        }

        let areas = normalizedDrafts.enumerated().map { index, draft in
            LifeArea(name: draft.name, icon: draft.icon, colorHex: draft.colorHex, order: index)
        }
        try lifeAreaRepository.insert(areas)
        try userSettingsRepository.updateOnboardingStep(.initialBalance)
    }
}
