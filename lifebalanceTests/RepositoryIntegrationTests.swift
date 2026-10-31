import Foundation
import SwiftData
import Testing
@testable import lifebalance

@MainActor
struct RepositoryIntegrationTests {
    @Test
    func taskRepositoryPersistsSortsUpdatesAndDeletes() throws {
        let container = try makeContainer()
        let repository = SwiftDataTaskRepository(context: container.mainContext)
        let older = TaskItem(title: "Старая", createdAt: Date(timeIntervalSince1970: 100))
        let newer = TaskItem(title: "Новая", createdAt: Date(timeIntervalSince1970: 200))

        try repository.insert(older)
        try repository.insert(newer)
        #expect(try repository.fetchAll().map(\.title) == ["Новая", "Старая"])

        newer.title = "Обновлённая"
        try repository.save()
        #expect(try repository.fetchAll().first?.title == "Обновлённая")

        try repository.delete(newer)
        #expect(try repository.fetchAll().map(\.title) == ["Старая"])
    }

    @Test
    func repositoriesPreserveTaskGoalAndAreaRelationships() throws {
        let container = try makeContainer()
        let areaRepository = SwiftDataLifeAreaRepository(context: container.mainContext)
        let goalRepository = SwiftDataGoalRepository(context: container.mainContext)
        let taskRepository = SwiftDataTaskRepository(context: container.mainContext)
        let area = LifeArea(name: "Работа", icon: "briefcase", colorHex: "#112233", order: 0)
        let goal = Goal(title: "Выпустить продукт", lifeArea: area)
        let task = TaskItem(title: "Подготовить релиз", lifeArea: area, goal: goal)

        try areaRepository.insert([area])
        try goalRepository.insert(goal)
        try taskRepository.insert(task)

        let loadedTask = try #require(taskRepository.fetchAll().first)
        let loadedGoal = try #require(goalRepository.fetchActive().first)
        #expect(loadedTask.lifeArea?.id == area.id)
        #expect(loadedTask.goal?.id == goal.id)
        #expect(loadedGoal.tasks.map(\.id) == [task.id])
    }

    @Test
    func lifeAreaAndGoalRepositoriesFilterAndSort() throws {
        let container = try makeContainer()
        let areaRepository = SwiftDataLifeAreaRepository(context: container.mainContext)
        let goalRepository = SwiftDataGoalRepository(context: container.mainContext)
        let second = LifeArea(name: "Вторая", icon: "2.circle", colorHex: "#222222", order: 1)
        let first = LifeArea(name: "Первая", icon: "1.circle", colorHex: "#111111", order: 0)
        let inactive = LifeArea(name: "Архив", icon: "archivebox", colorHex: "#333333", order: 2, isActive: false)

        try areaRepository.insert([second, inactive, first])
        #expect(try areaRepository.fetchActiveAreas().map(\.name) == ["Первая", "Вторая"])

        try goalRepository.insert(Goal(title: "Старая активная", createdAt: Date(timeIntervalSince1970: 100)))
        try goalRepository.insert(Goal(title: "Новая активная", createdAt: Date(timeIntervalSince1970: 200)))
        try goalRepository.insert(Goal(title: "Завершённая", status: .completed, createdAt: Date(timeIntervalSince1970: 300)))
        #expect(try goalRepository.fetchActive().map(\.title) == ["Новая активная", "Старая активная"])
    }

    @Test
    func userSettingsRepositoryCreatesOnlyOneSettingsRow() throws {
        let container = try makeContainer()
        let repository = SwiftDataUserSettingsRepository(context: container.mainContext)

        let first = try repository.fetchOrCreate()
        try repository.updateOnboardingStep(.completed)
        let second = try repository.fetchOrCreate()
        let rows = try container.mainContext.fetch(FetchDescriptor<UserSettings>())

        #expect(first.id == second.id)
        #expect(second.onboardingStep == .completed)
        #expect(rows.count == 1)
    }

    @Test
    func balanceRepositoryUpsertsTodayAndRemovesOldRatings() throws {
        let container = try makeContainer()
        let areaRepository = SwiftDataLifeAreaRepository(context: container.mainContext)
        let repository = SwiftDataBalanceRepository(context: container.mainContext)
        let health = LifeArea(name: "Здоровье", icon: "heart", colorHex: "#FF0000", order: 0)
        let work = LifeArea(name: "Работа", icon: "briefcase", colorHex: "#0000FF", order: 1)
        try areaRepository.insert([health, work])

        try repository.upsertTodaySnapshot(
            ratings: [AreaRatingInput(area: health, value: 4, note: "Утро")],
            note: "Первый"
        )
        let originalRatingID = try #require(repository.fetchLatestSnapshot()?.ratings.first?.id)

        try repository.upsertTodaySnapshot(
            ratings: [AreaRatingInput(area: work, value: 8, note: "Вечер")],
            note: "Обновлённый"
        )

        let snapshots = try container.mainContext.fetch(FetchDescriptor<BalanceSnapshot>())
        let ratings = try container.mainContext.fetch(FetchDescriptor<BalanceRating>())
        let fetchedLatest = try repository.fetchLatestSnapshot()
        let latest = try #require(fetchedLatest)
        #expect(snapshots.count == 1)
        #expect(latest.note == "Обновлённый")
        #expect(latest.ratings.count == 1)
        #expect(latest.ratings.first?.area?.id == work.id)
        #expect(ratings.count == 1)
        #expect(ratings.first?.id != originalRatingID)
    }

    @Test
    func focusRepositoryReturnsNewestActiveSession() throws {
        let container = try makeContainer()
        let repository = SwiftDataFocusSessionRepository(context: container.mainContext)
        let oldRunning = FocusSession(
            startAt: Date(timeIntervalSince1970: 100),
            plannedSeconds: 600,
            status: .running
        )
        let completed = FocusSession(
            startAt: Date(timeIntervalSince1970: 300),
            plannedSeconds: 600,
            status: .completed
        )
        let newPaused = FocusSession(
            startAt: Date(timeIntervalSince1970: 200),
            plannedSeconds: 600,
            status: .paused
        )

        try repository.insert(oldRunning)
        try repository.insert(completed)
        try repository.insert(newPaused)

        #expect(try repository.fetchActiveSession()?.id == newPaused.id)
        #expect(try repository.fetchAll().map(\.id) == [completed.id, newPaused.id, oldRunning.id])
    }

    private func makeContainer() throws -> ModelContainer {
        try AppPersistence.makeContainer(isStoredInMemoryOnly: true)
    }
}
