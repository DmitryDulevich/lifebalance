import Foundation

enum GoalStatusTransitionError: LocalizedError {
    case invalidTransition(from: GoalStatus, to: GoalStatus)

    var errorDescription: String? {
        "Недопустимый переход между состояниями цели."
    }
}

@MainActor
final class SetGoalStatusUseCase {
    private let goalRepository: GoalRepository

    init(goalRepository: GoalRepository) {
        self.goalRepository = goalRepository
    }

    func execute(_ goal: Goal, status: GoalStatus) throws {
        guard goal.status != status else { return }
        guard Self.allowedTransitions[goal.status, default: []].contains(status) else {
            throw GoalStatusTransitionError.invalidTransition(from: goal.status, to: status)
        }

        let previousStatus = goal.status
        goal.status = status
        do {
            try goalRepository.save()
        } catch {
            goal.status = previousStatus
            throw error
        }
    }

    private static let allowedTransitions: [GoalStatus: Set<GoalStatus>] = [
        .active: [.paused, .completed, .archived],
        .paused: [.active, .completed, .archived],
        .completed: [.active, .archived],
        .archived: [.active]
    ]
}
