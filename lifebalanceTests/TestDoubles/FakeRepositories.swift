import Foundation
@testable import lifebalance

enum FakeRepositoryError: Error {
    case forcedFailure
}

@MainActor
final class FakeTaskRepository: TaskRepository {
    var tasks: [TaskItem] = []
    private(set) var insertedTasks: [TaskItem] = []
    private(set) var deletedTasks: [TaskItem] = []
    private(set) var saveCallCount = 0
    var saveError: Error?

    func fetchAll() throws -> [TaskItem] {
        tasks
    }

    func insert(_ task: TaskItem) throws {
        tasks.append(task)
        insertedTasks.append(task)
    }

    func delete(_ task: TaskItem) throws {
        tasks.removeAll { $0.id == task.id }
        deletedTasks.append(task)
    }

    func save() throws {
        saveCallCount += 1
        if let saveError { throw saveError }
    }
}

@MainActor
final class FakeFocusSessionRepository: FocusSessionRepository {
    var activeSession: FocusSession?
    var sessions: [FocusSession] = []
    private(set) var insertedSessions: [FocusSession] = []
    private(set) var saveCallCount = 0

    func fetchActiveSession() throws -> FocusSession? {
        activeSession
    }

    func fetchAll() throws -> [FocusSession] {
        sessions
    }

    func insert(_ session: FocusSession) throws {
        activeSession = session
        sessions.append(session)
        insertedSessions.append(session)
    }

    func save() throws {
        saveCallCount += 1
    }
}

@MainActor
final class FakeLifeAreaRepository: LifeAreaRepository {
    var activeAreas: [LifeArea] = []
    private(set) var insertedBatches: [[LifeArea]] = []

    func fetchActiveAreas() throws -> [LifeArea] {
        activeAreas
    }

    func insert(_ areas: [LifeArea]) throws {
        activeAreas.append(contentsOf: areas)
        insertedBatches.append(areas)
    }
}

@MainActor
final class FakeUserSettingsRepository: UserSettingsRepository {
    var settings = UserSettings()
    private(set) var updatedSteps: [OnboardingStep] = []
    var updateError: Error?

    func fetchOrCreate() throws -> UserSettings {
        settings
    }

    func updateOnboardingStep(_ step: OnboardingStep) throws {
        if let updateError { throw updateError }
        settings.onboardingStep = step
        updatedSteps.append(step)
    }
}

@MainActor
final class FakeGoalRepository: GoalRepository {
    var activeGoals: [Goal] = []
    private(set) var insertedGoals: [Goal] = []
    private(set) var saveCallCount = 0

    func fetchActive() throws -> [Goal] {
        activeGoals
    }

    func insert(_ goal: Goal) throws {
        activeGoals.append(goal)
        insertedGoals.append(goal)
    }

    func save() throws {
        saveCallCount += 1
    }
}

@MainActor
final class FakeBalanceRepository: BalanceRepository {
    var latestSnapshot: BalanceSnapshot?
    private(set) var savedSnapshotCallCount = 0
    private(set) var upsertCallCount = 0
    private(set) var lastRatings: [AreaRatingInput] = []
    private(set) var lastNote: String?

    func saveSnapshot(ratings: [AreaRatingInput], note: String?) throws {
        savedSnapshotCallCount += 1
        lastRatings = ratings
        lastNote = note
    }

    func fetchLatestSnapshot() throws -> BalanceSnapshot? {
        latestSnapshot
    }

    func upsertTodaySnapshot(ratings: [AreaRatingInput], note: String?) throws {
        upsertCallCount += 1
        lastRatings = ratings
        lastNote = note
        if latestSnapshot == nil {
            latestSnapshot = BalanceSnapshot(note: note)
        }
    }
}
