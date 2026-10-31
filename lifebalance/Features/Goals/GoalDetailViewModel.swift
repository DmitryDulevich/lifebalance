import Foundation
import Observation

@Observable
@MainActor
final class GoalDetailViewModel {
    let goal: Goal
    var showTaskForm = false
    var errorMessage: String?
    private(set) var tasks: [TaskItem]
    private(set) var progress: GoalProgress

    private let toggleTaskCompletionUseCase: ToggleTaskCompletionUseCase

    init(
        goal: Goal,
        toggleTaskCompletionUseCase: ToggleTaskCompletionUseCase
    ) {
        self.goal = goal
        self.toggleTaskCompletionUseCase = toggleTaskCompletionUseCase
        self.tasks = Self.sortedTasks(for: goal)
        self.progress = GoalProgressCalculator.summary(for: goal)
    }

    var canAddTask: Bool {
        goal.status == .active
    }

    func toggleCompletion(_ task: TaskItem) {
        do {
            try toggleTaskCompletionUseCase.execute(task)
            errorMessage = nil
            reloadPresentationState()
        } catch {
            AppLogger.error(error, context: "goal_detail.toggle_task")
            errorMessage = error.localizedDescription
        }
    }

    func taskWasSaved() {
        reloadPresentationState()
    }

    private func reloadPresentationState() {
        tasks = Self.sortedTasks(for: goal)
        progress = GoalProgressCalculator.summary(for: goal)
    }

    private static func sortedTasks(for goal: Goal) -> [TaskItem] {
        goal.tasks.sorted {
            if $0.status != $1.status {
                return $0.status == .active
            }
            return $0.createdAt > $1.createdAt
        }
    }
}
