import Foundation
import Testing
@testable import lifebalance

@Suite("Focus session use cases")
@MainActor
struct FocusSessionUseCasesTests {
    @Test("Starting focus creates one running session")
    func startsSession() throws {
        let repository = FakeFocusSessionRepository()
        let useCase = StartFocusSessionUseCase(focusSessionRepository: repository)
        let area = LifeArea(name: "Работа", icon: "briefcase", colorHex: "112233", order: 0)
        let goal = Goal(title: "Релиз", lifeArea: area)
        let task = TaskItem(title: "Deep work", lifeArea: area, goal: goal)

        let session = try useCase.execute(task: task, plannedSeconds: 1_500)

        #expect(session.status == .running)
        #expect(session.plannedSeconds == 1_500)
        #expect(session.task === task)
        #expect(session.taskIDSnapshot == task.id)
        #expect(session.taskTitleSnapshot == "Deep work")
        #expect(session.lifeAreaIDSnapshot == area.id)
        #expect(session.lifeAreaNameSnapshot == "Работа")
        #expect(session.lifeAreaColorHexSnapshot == "112233")
        #expect(session.goalIDSnapshot == goal.id)
        #expect(session.goalTitleSnapshot == "Релиз")
        #expect(repository.insertedSessions.count == 1)
    }

    @Test("A second active session is rejected")
    func rejectsSecondSession() {
        let repository = FakeFocusSessionRepository()
        repository.activeSession = FocusSession(plannedSeconds: 1_500)
        let useCase = StartFocusSessionUseCase(focusSessionRepository: repository)

        #expect(throws: StartFocusSessionUseCase.ActiveSessionError.self) {
            try useCase.execute(task: nil, plannedSeconds: 1_500)
        }
        #expect(repository.insertedSessions.isEmpty)
    }

    @Test("Invalid focus duration is rejected")
    func rejectsInvalidDuration() {
        let repository = FakeFocusSessionRepository()
        let useCase = StartFocusSessionUseCase(focusSessionRepository: repository)

        #expect(throws: StartFocusSessionUseCase.ActiveSessionError.self) {
            try useCase.execute(task: nil, plannedSeconds: 0)
        }
        #expect(repository.insertedSessions.isEmpty)
    }

    @Test("Expired running session is completed during restoration")
    func restoresExpiredSession() throws {
        let start = Date(timeIntervalSince1970: 1_000)
        let now = start.addingTimeInterval(120)
        let session = FocusSession(startAt: start, plannedSeconds: 60)
        let focusRepository = FakeFocusSessionRepository()
        focusRepository.activeSession = session
        let taskRepository = FakeTaskRepository()
        let finishUseCase = FinishFocusSessionUseCase(
            focusSessionRepository: focusRepository,
            taskRepository: taskRepository
        )
        let restoreUseCase = RestoreActiveFocusSessionUseCase(
            focusSessionRepository: focusRepository,
            finishFocusSessionUseCase: finishUseCase
        )

        let restored = try restoreUseCase.execute(at: now)

        #expect(restored === session)
        #expect(session.status == .completed)
        #expect(session.endAt == start.addingTimeInterval(60))
        #expect(focusRepository.saveCallCount == 1)
    }

    @Test("Finishing a paused session records its final pause and completes its task")
    func finishesPausedSession() throws {
        let start = Date(timeIntervalSince1970: 2_000)
        let pausedAt = start.addingTimeInterval(30)
        let end = pausedAt.addingTimeInterval(20)
        let task = TaskItem(title: "Review architecture")
        let session = FocusSession(
            startAt: start,
            plannedSeconds: 300,
            pausedSeconds: 10,
            pausedAt: pausedAt,
            status: .paused,
            task: task
        )
        let focusRepository = FakeFocusSessionRepository()
        let taskRepository = FakeTaskRepository()
        let useCase = FinishFocusSessionUseCase(
            focusSessionRepository: focusRepository,
            taskRepository: taskRepository
        )

        try useCase.execute(session, completeTask: true, endedAt: end)

        #expect(session.status == .completed)
        #expect(session.endAt == end)
        #expect(session.pausedAt == nil)
        #expect(session.pausedSeconds == 30)
        #expect(task.status == .completed)
        #expect(task.completedAt == end)
        #expect(focusRepository.saveCallCount == 1)
        #expect(taskRepository.saveCallCount == 1)
    }

    @Test("Failed persistence restores the running session")
    func finishRollsBackOnFailure() {
        let session = FocusSession(plannedSeconds: 300)
        let focusRepository = FakeFocusSessionRepository()
        focusRepository.saveError = FakeRepositoryError.forcedFailure
        let useCase = FinishFocusSessionUseCase(
            focusSessionRepository: focusRepository,
            taskRepository: FakeTaskRepository()
        )

        #expect(throws: FakeRepositoryError.self) {
            try useCase.execute(session, completeTask: false)
        }
        #expect(session.status == .running)
        #expect(session.endAt == nil)
        #expect(session.pausedAt == nil)
    }
}
