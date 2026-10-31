import Foundation

enum GoalValidationError: LocalizedError {
    case emptyTitle
    case titleTooLong

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Введите название цели."
        case .titleTooLong:
            return "Название цели не должно превышать 120 символов."
        }
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
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { throw GoalValidationError.emptyTitle }
        guard trimmedTitle.count <= 120 else { throw GoalValidationError.titleTooLong }

        let goal = Goal(title: trimmedTitle, targetDate: targetDate, lifeArea: lifeArea)
        try goalRepository.insert(goal)
        return goal
    }
}
