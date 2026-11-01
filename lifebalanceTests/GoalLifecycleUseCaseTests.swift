import Foundation
import Testing
@testable import lifebalance

@Suite("Goal lifecycle")
@MainActor
struct GoalLifecycleUseCaseTests {
    @Test
    func updatesAndNormalizesGoal() throws {
        let repository = FakeGoalRepository()
        let oldArea = LifeArea(name: "Работа", icon: "briefcase", colorHex: "000000", order: 0)
        let newArea = LifeArea(name: "Обучение", icon: "book", colorHex: "111111", order: 1)
        let goal = Goal(title: "Старая цель", lifeArea: oldArea)
        repository.activeGoals = [goal]
        let targetDate = Date(timeIntervalSince1970: 10_000)
        let useCase = UpdateGoalUseCase(goalRepository: repository)

        try useCase.execute(
            goal,
            with: GoalInput(title: "  Новая цель  ", lifeArea: newArea, targetDate: targetDate)
        )

        #expect(goal.title == "Новая цель")
        #expect(goal.lifeArea?.id == newArea.id)
        #expect(goal.targetDate == targetDate)
        #expect(repository.saveCallCount == 1)
    }

    @Test
    func updateRollsBackOnPersistenceFailure() {
        let repository = FakeGoalRepository()
        let goal = Goal(title: "Исходная цель")
        repository.activeGoals = [goal]
        repository.saveError = FakeRepositoryError.forcedFailure
        let useCase = UpdateGoalUseCase(goalRepository: repository)

        #expect(throws: FakeRepositoryError.self) {
            try useCase.execute(
                goal,
                with: GoalInput(title: "Новое название", lifeArea: nil, targetDate: .now)
            )
        }
        #expect(goal.title == "Исходная цель")
        #expect(goal.targetDate == nil)
    }

    @Test
    func supportsPauseCompleteArchiveAndRestore() throws {
        let repository = FakeGoalRepository()
        let goal = Goal(title: "Цель")
        try repository.insert(goal)
        let useCase = SetGoalStatusUseCase(goalRepository: repository)

        let pausedAt = Date(timeIntervalSince1970: 100)
        let completedAt = Date(timeIntervalSince1970: 200)
        let archivedAt = Date(timeIntervalSince1970: 300)
        let restoredAt = Date(timeIntervalSince1970: 400)

        try useCase.execute(goal, status: .paused, at: pausedAt)
        #expect(goal.status == .paused)
        try useCase.execute(goal, status: .completed, at: completedAt)
        #expect(goal.status == .completed)
        try useCase.execute(goal, status: .archived, at: archivedAt)
        #expect(goal.status == .archived)
        try useCase.execute(goal, status: .active, at: restoredAt)
        #expect(goal.status == .active)
        #expect(repository.statusEvents.map(\.status) == [.active, .paused, .completed, .archived, .active])
        #expect(repository.statusEvents.map(\.changedAt) == [goal.createdAt, pausedAt, completedAt, archivedAt, restoredAt])
    }

    @Test
    func rejectsInvalidArchivedToCompletedTransition() {
        let repository = FakeGoalRepository()
        let goal = Goal(title: "Архивная", status: .archived)
        repository.otherGoals = [goal]
        let useCase = SetGoalStatusUseCase(goalRepository: repository)

        #expect(throws: GoalStatusTransitionError.self) {
            try useCase.execute(goal, status: .completed)
        }
        #expect(goal.status == .archived)
        #expect(repository.saveCallCount == 0)
    }

    @Test
    func statusRollsBackOnPersistenceFailure() throws {
        let repository = FakeGoalRepository()
        let goal = Goal(title: "Активная")
        try repository.insert(goal)
        repository.saveError = FakeRepositoryError.forcedFailure
        let useCase = SetGoalStatusUseCase(goalRepository: repository)

        #expect(throws: FakeRepositoryError.self) {
            try useCase.execute(goal, status: .archived)
        }
        #expect(goal.status == .active)
        #expect(repository.statusEvents.map(\.status) == [.active])
    }
}
