import Foundation
import Observation

@Observable
@MainActor
final class GoalDetailViewModel {
    let goal: Goal
    var showTaskForm = false
    var showCompletionPrompt = false
    var errorMessage: String?
    private(set) var editingTask: TaskItem?
    private(set) var tasks: [TaskItem]
    private(set) var progress: GoalProgress

    private let toggleTaskCompletionUseCase: ToggleTaskCompletionUseCase
    private let deleteTaskUseCase: DeleteTaskUseCase
    private let setGoalStatusUseCase: SetGoalStatusUseCase

    init(
        goal: Goal,
        toggleTaskCompletionUseCase: ToggleTaskCompletionUseCase,
        deleteTaskUseCase: DeleteTaskUseCase,
        setGoalStatusUseCase: SetGoalStatusUseCase
    ) {
        self.goal = goal
        self.toggleTaskCompletionUseCase = toggleTaskCompletionUseCase
        self.deleteTaskUseCase = deleteTaskUseCase
        self.setGoalStatusUseCase = setGoalStatusUseCase
        self.tasks = Self.sortedTasks(for: goal)
        self.progress = GoalProgressCalculator.summary(for: goal)
    }

    var canAddTask: Bool {
        goal.status == .active || goal.status == .paused
    }

    var canModifyTasks: Bool {
        goal.status != .archived
    }

    func startCreatingTask() {
        guard canAddTask else { return }
        editingTask = nil
        showTaskForm = true
    }

    func startEditing(_ task: TaskItem) {
        guard canModifyTasks else { return }
        editingTask = task
        showTaskForm = true
    }

    func toggleCompletion(_ task: TaskItem) {
        guard canModifyTasks else { return }
        let previousProgress = progress
        do {
            try toggleTaskCompletionUseCase.execute(task)
            errorMessage = nil
            reloadPresentationState()
            if previousProgress.fraction < 1,
               progress.totalTaskCount > 0,
               progress.fraction == 1,
               goal.status == .active || goal.status == .paused {
                showCompletionPrompt = true
            }
        } catch {
            AppLogger.error(error, context: "goal_detail.toggle_task")
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ task: TaskItem) {
        guard canModifyTasks else { return }
        do {
            try deleteTaskUseCase.execute(task)
            tasks.removeAll { $0.id == task.id }
            progress = GoalProgressCalculator.summary(for: tasks)
            errorMessage = nil
        } catch {
            AppLogger.error(error, context: "goal_detail.delete_task")
            errorMessage = error.localizedDescription
        }
    }

    func completeGoal() {
        do {
            try setGoalStatusUseCase.execute(goal, status: .completed)
            showCompletionPrompt = false
            errorMessage = nil
        } catch {
            AppLogger.error(error, context: "goal_detail.complete_goal")
            errorMessage = error.localizedDescription
        }
    }

    func keepGoalOpen() {
        showCompletionPrompt = false
    }

    func taskWasSaved() {
        reloadPresentationState()
    }

    private func reloadPresentationState() {
        tasks = Self.sortedTasks(for: goal)
        progress = GoalProgressCalculator.summary(for: tasks)
    }

    private static func sortedTasks(for goal: Goal) -> [TaskItem] {
        goal.tasks.filter { $0.status != .archived }.sorted {
            if $0.status != $1.status {
                return $0.status == .active
            }
            return $0.createdAt > $1.createdAt
        }
    }
}
