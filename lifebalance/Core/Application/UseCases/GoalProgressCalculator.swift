import Foundation

struct GoalProgress: Equatable, Sendable {
    let completedTaskCount: Int
    let totalTaskCount: Int

    var fraction: Double {
        guard totalTaskCount > 0 else { return 0 }
        return Double(completedTaskCount) / Double(totalTaskCount)
    }

    var percentage: Int {
        Int((fraction * 100).rounded())
    }
}

/// Progress "by tasks" per PRD §4.3: completed / total of the goal's own tasks.
enum GoalProgressCalculator {
    static func summary(for goal: Goal) -> GoalProgress {
        summary(for: goal.tasks)
    }

    static func summary(for tasks: [TaskItem]) -> GoalProgress {
        let progressTasks = tasks.filter { $0.status != .archived }
        return GoalProgress(
            completedTaskCount: progressTasks.lazy.filter { $0.status == .completed }.count,
            totalTaskCount: progressTasks.count
        )
    }

    static func progress(for goal: Goal) -> Double {
        summary(for: goal).fraction
    }
}
