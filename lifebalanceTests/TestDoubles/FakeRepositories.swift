import Foundation
@testable import lifebalance

@MainActor
final class FakeTaskRepository: TaskRepository {
    var tasks: [TaskItem] = []
    private(set) var insertedTasks: [TaskItem] = []
    private(set) var deletedTasks: [TaskItem] = []
    private(set) var saveCallCount = 0

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

    func fetchOrCreate() throws -> UserSettings {
        settings
    }

    func updateOnboardingStep(_ step: OnboardingStep) throws {
        settings.onboardingStep = step
        updatedSteps.append(step)
    }
}
