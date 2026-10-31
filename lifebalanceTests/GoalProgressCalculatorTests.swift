import Testing
@testable import lifebalance

@Suite("Goal progress")
@MainActor
struct GoalProgressCalculatorTests {
    @Test("Goal without tasks has zero progress")
    func emptyGoal() {
        let goal = Goal(title: "Learn Swift")

        #expect(GoalProgressCalculator.progress(for: goal) == 0)
    }

    @Test("Progress is completed tasks divided by all goal tasks")
    func completedFraction() {
        let goal = Goal(title: "Release app")
        goal.tasks = [
            TaskItem(title: "Design", status: .completed),
            TaskItem(title: "Implement", status: .completed),
            TaskItem(title: "Publish")
        ]

        #expect(GoalProgressCalculator.progress(for: goal) == 2.0 / 3.0)
    }
}
