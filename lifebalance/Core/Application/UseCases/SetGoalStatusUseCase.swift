import Foundation

enum GoalStatusTransitionError: LocalizedError {
    case invalidTransition(from: GoalStatus, to: GoalStatus)

    var errorDescription: String? {
        String(localized: "Недопустимый переход между состояниями цели.")
    }
}

@MainActor
final class SetGoalStatusUseCase {
    private let goalRepository: GoalRepository

    init(goalRepository: GoalRepository) {
        self.goalRepository = goalRepository
    }

    func execute(_ goal: Goal, status: GoalStatus, at changedAt: Date = .now) throws {
        guard goal.status != status else { return }
        guard Self.allowedTransitions[goal.status, default: []].contains(status) else {
            throw GoalStatusTransitionError.invalidTransition(from: goal.status, to: status)
        }

        let previousStatus = goal.status
        let event = GoalStatusEvent(
            goalID: goal.id,
            goalTitleSnapshot: goal.title,
            status: status,
            changedAt: changedAt
        )
        goal.status = status
        do {
            try goalRepository.save(recording: event)
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
