import Foundation
import Testing
@testable import lifebalance

@Suite("Build analytics")
@MainActor
struct BuildAnalyticsUseCaseTests {
    @Test("Aggregates focus, tasks, goals, areas and balance for selected period")
    func buildsReport() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 18))!
        let work = LifeArea(name: "Работа", icon: "briefcase", colorHex: "3284D0", order: 0)
        let taskRepository = FakeTaskRepository()
        let focusRepository = FakeFocusSessionRepository()
        let goalRepository = FakeGoalRepository()
        let balanceRepository = FakeBalanceRepository()

        let focusTask = TaskItem(title: "Фокус", lifeArea: work)
        focusRepository.sessions = [
            FocusSession(
                startAt: now.addingTimeInterval(-1_800),
                endAt: now,
                plannedSeconds: 1_800,
                pausedSeconds: 300,
                status: .completed,
                task: focusTask
            ),
            FocusSession(
                startAt: now.addingTimeInterval(-10 * 86_400),
                endAt: now.addingTimeInterval(-10 * 86_400 + 600),
                plannedSeconds: 600,
                status: .completed
            )
        ]
        taskRepository.tasks = [
            TaskItem(title: "Done", status: .completed, completedAt: now.addingTimeInterval(-600)),
            TaskItem(title: "Archived done", status: .archived, completedAt: now.addingTimeInterval(-1_200))
        ]
        let activeGoal = Goal(title: "Релиз", createdAt: now.addingTimeInterval(-86_400))
        activeGoal.tasks = [TaskItem(title: "Step", status: .completed)]
        goalRepository.activeGoals = [activeGoal]
        goalRepository.otherGoals = [Goal(title: "Finished", status: .completed, createdAt: now.addingTimeInterval(-172_800))]
        let snapshot = BalanceSnapshot(createdAt: now.addingTimeInterval(-3_600))
        snapshot.ratings = [
            BalanceRating(value: 6, area: work, snapshot: snapshot),
            BalanceRating(value: 8, area: work, snapshot: snapshot)
        ]
        balanceRepository.snapshots = [snapshot]

        let useCase = BuildAnalyticsUseCase(
            focusSessionRepository: focusRepository,
            taskRepository: taskRepository,
            goalRepository: goalRepository,
            balanceRepository: balanceRepository
        )

        let report = try useCase.execute(period: .sevenDays, now: now, calendar: calendar)

        #expect(report.totalFocusMinutes == 25)
        #expect(report.completedFocusSessions == 1)
        #expect(report.completedTasks == 2)
        #expect(report.createdGoals == 2)
        #expect(report.focusByArea.first?.name == "Работа")
        #expect(report.focusByArea.first?.minutes == 25)
        #expect(report.goals.first?.progress.percentage == 100)
        #expect(report.balanceHistory.first?.average == 7)
        #expect(report.daily.count == 7)
        #expect(report.daily.last?.focusMinutes == 25)
        #expect(report.daily.last?.completedTasks == 2)
    }
}
