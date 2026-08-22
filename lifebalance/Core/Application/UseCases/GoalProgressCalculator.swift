import Foundation

/// Progress "by tasks" per PRD §4.3: completed / total of the goal's own tasks.
enum GoalProgressCalculator {
    static func progress(for goal: Goal) -> Double {
        guard !goal.tasks.isEmpty else { return 0 }
        let completed = goal.tasks.filter { $0.status == .completed }.count
        return Double(completed) / Double(goal.tasks.count)
    }
}
