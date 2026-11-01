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

        let progress = GoalProgressCalculator.summary(for: goal)

        #expect(progress.completedTaskCount == 2)
        #expect(progress.totalTaskCount == 3)
        #expect(progress.fraction == 2.0 / 3.0)
        #expect(progress.percentage == 67)
    }

    @Test("Archived tasks do not affect goal progress")
    func ignoresArchivedTasks() {
        let goal = Goal(title: "Release app")
        goal.tasks = [
            TaskItem(title: "Done", status: .completed),
            TaskItem(title: "Removed from plan", status: .archived)
        ]

        let progress = GoalProgressCalculator.summary(for: goal)

        #expect(progress.completedTaskCount == 1)
        #expect(progress.totalTaskCount == 1)
        #expect(progress.percentage == 100)
    }
}
