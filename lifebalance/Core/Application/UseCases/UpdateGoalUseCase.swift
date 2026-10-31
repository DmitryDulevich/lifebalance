import Foundation

struct GoalInput {
    let title: String
    let lifeArea: LifeArea?
    let targetDate: Date?
}

@MainActor
final class UpdateGoalUseCase {
    private let goalRepository: GoalRepository

    init(goalRepository: GoalRepository) {
        self.goalRepository = goalRepository
    }

    func execute(_ goal: Goal, with input: GoalInput) throws {
        let title = try GoalInputValidator.normalizedTitle(input.title)
        let previous = (goal.title, goal.lifeArea, goal.targetDate)

        goal.title = title
        goal.lifeArea = input.lifeArea
        goal.targetDate = input.targetDate

        do {
            try goalRepository.save()
        } catch {
            (goal.title, goal.lifeArea, goal.targetDate) = previous
            throw error
        }
    }
}
