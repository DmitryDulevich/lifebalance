import Foundation

enum GoalValidationError: LocalizedError {
    case emptyTitle
    case titleTooLong

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return String(localized: "Введите название цели.")
        case .titleTooLong:
            return String(localized: "Название цели не должно превышать 120 символов.")
        }
    }
}

enum GoalInputValidator {
    static let maximumTitleLength = 120

    static func normalizedTitle(_ title: String) throws -> String {
        let normalized = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { throw GoalValidationError.emptyTitle }
        guard normalized.count <= maximumTitleLength else { throw GoalValidationError.titleTooLong }
        return normalized
    }
}

@MainActor
final class CreateGoalUseCase {
    private let goalRepository: GoalRepository

    init(goalRepository: GoalRepository) {
        self.goalRepository = goalRepository
    }

    @discardableResult
    func execute(title: String, lifeArea: LifeArea?, targetDate: Date?) throws -> Goal {
        let trimmedTitle = try GoalInputValidator.normalizedTitle(title)

        let goal = Goal(title: trimmedTitle, targetDate: targetDate, lifeArea: lifeArea)
        try goalRepository.insert(goal)
        return goal
    }
}
