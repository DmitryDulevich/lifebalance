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
    var fetchError: Error?
    var insertError: Error?
    var deleteError: Error?
    var saveError: Error?

    func fetchAll() throws -> [TaskItem] {
        if let fetchError { throw fetchError }
        return tasks
    }

    func insert(_ task: TaskItem) throws {
        if let insertError { throw insertError }
        tasks.append(task)
        insertedTasks.append(task)
    }

    func delete(_ task: TaskItem) throws {
        if let deleteError { throw deleteError }
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
    var fetchError: Error?
    var insertError: Error?
    var saveError: Error?

    func fetchActiveSession() throws -> FocusSession? {
        if let fetchError { throw fetchError }
        return activeSession
    }

    func fetchAll() throws -> [FocusSession] {
        if let fetchError { throw fetchError }
        return sessions
    }

    func insert(_ session: FocusSession) throws {
        if let insertError { throw insertError }
        activeSession = session
        sessions.append(session)
        insertedSessions.append(session)
    }

    func save() throws {
        saveCallCount += 1
        if let saveError { throw saveError }
    }
}

@MainActor
final class FakeLifeAreaRepository: LifeAreaRepository {
    var activeAreas: [LifeArea] = []
    var inactiveAreas: [LifeArea] = []
    private(set) var insertedBatches: [[LifeArea]] = []
    private(set) var saveCallCount = 0
    var fetchError: Error?
    var insertError: Error?
    var saveError: Error?

    func fetchActiveAreas() throws -> [LifeArea] {
        if let fetchError { throw fetchError }
        return activeAreas
    }

    func fetchAllAreas() throws -> [LifeArea] {
        if let fetchError { throw fetchError }
        return (activeAreas + inactiveAreas).sorted { $0.order < $1.order }
    }

    func insert(_ areas: [LifeArea]) throws {
        if let insertError { throw insertError }
        activeAreas.append(contentsOf: areas)
        insertedBatches.append(areas)
    }

    func save() throws {
        saveCallCount += 1
        if let saveError { throw saveError }
        inactiveAreas.append(contentsOf: activeAreas.filter { !$0.isActive })
        activeAreas.removeAll { !$0.isActive }
        activeAreas.append(contentsOf: inactiveAreas.filter(\.isActive))
        inactiveAreas.removeAll(where: \.isActive)
        activeAreas.sort { $0.order < $1.order }
    }
}

@MainActor
final class FakeUserSettingsRepository: UserSettingsRepository {
    var settings = UserSettings()
    private(set) var updatedSteps: [OnboardingStep] = []
    var fetchError: Error?
    var updateError: Error?

    func fetchOrCreate() throws -> UserSettings {
        if let fetchError { throw fetchError }
        return settings
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
    var otherGoals: [Goal] = []
    private(set) var insertedGoals: [Goal] = []
    private(set) var saveCallCount = 0
    var fetchError: Error?
    var insertError: Error?
    var saveError: Error?

    func fetchActive() throws -> [Goal] {
        if let fetchError { throw fetchError }
        return (activeGoals + otherGoals).filter { $0.status == .active }
    }

    func fetchAll() throws -> [Goal] {
        if let fetchError { throw fetchError }
        return (activeGoals + otherGoals).sorted { $0.createdAt > $1.createdAt }
    }

    func insert(_ goal: Goal) throws {
        if let insertError { throw insertError }
        if goal.status == .active {
            activeGoals.append(goal)
        } else {
            otherGoals.append(goal)
        }
        insertedGoals.append(goal)
    }

    func save() throws {
        saveCallCount += 1
        if let saveError { throw saveError }
    }
}

@MainActor
final class FakeBalanceRepository: BalanceRepository {
    var latestSnapshot: BalanceSnapshot?
    var snapshots: [BalanceSnapshot] = []
    private(set) var savedSnapshotCallCount = 0
    private(set) var upsertCallCount = 0
    private(set) var lastRatings: [AreaRatingInput] = []
    private(set) var lastNote: String?
    var fetchError: Error?
    var saveError: Error?

    func saveSnapshot(ratings: [AreaRatingInput], note: String?) throws {
        if let saveError { throw saveError }
        savedSnapshotCallCount += 1
        lastRatings = ratings
        lastNote = note
    }

    func fetchLatestSnapshot() throws -> BalanceSnapshot? {
        if let fetchError { throw fetchError }
        return latestSnapshot
    }

    func fetchAllSnapshots() throws -> [BalanceSnapshot] {
        if let fetchError { throw fetchError }
        if !snapshots.isEmpty {
            return snapshots.sorted { $0.createdAt < $1.createdAt }
        }
        return latestSnapshot.map { [$0] } ?? []
    }

    func upsertTodaySnapshot(ratings: [AreaRatingInput], note: String?) throws {
        if let saveError { throw saveError }
        upsertCallCount += 1
        lastRatings = ratings
        lastNote = note
        if latestSnapshot == nil {
            latestSnapshot = BalanceSnapshot(note: note)
        }
    }
}

@MainActor
final class FakeFocusNotificationScheduler: FocusNotificationScheduling {
    struct ScheduledNotification {
        let sessionID: UUID
        let taskTitle: String?
        let timeInterval: TimeInterval
    }

    private(set) var scheduledNotifications: [ScheduledNotification] = []
    private(set) var cancelledSessionIDs: [UUID] = []

    func scheduleCompletion(sessionID: UUID, taskTitle: String?, after timeInterval: TimeInterval) {
        scheduledNotifications.append(ScheduledNotification(
            sessionID: sessionID,
            taskTitle: taskTitle,
            timeInterval: timeInterval
        ))
    }

    func cancelCompletion(sessionID: UUID) {
        cancelledSessionIDs.append(sessionID)
    }
}
