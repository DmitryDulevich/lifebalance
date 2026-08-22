import Foundation

enum GoalValidationError: LocalizedError {
    case emptyTitle

    var errorDescription: String? {
        "Введите название цели."
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

        let goal = Goal(title: trimmedTitle, targetDate: targetDate, lifeArea: lifeArea)
        try goalRepository.insert(goal)
        return goal
    }
}
