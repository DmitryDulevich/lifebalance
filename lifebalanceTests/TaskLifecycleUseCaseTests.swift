import Foundation
import Testing
@testable import lifebalance

@Suite("Task lifecycle")
@MainActor
struct TaskLifecycleUseCaseTests {
    @Test("Task can be completed, archived and restored")
    func supportsLifecycleTransitions() throws {
        let repository = FakeTaskRepository()
        let useCase = SetTaskStatusUseCase(taskRepository: repository)
        let task = TaskItem(title: "Подготовить релиз")

        try useCase.execute(task, status: .completed)
        #expect(task.status == .completed)
        #expect(task.completedAt != nil)
        let completedAt = task.completedAt

        try useCase.execute(task, status: .archived)
        #expect(task.status == .archived)
        #expect(task.completedAt == completedAt)

        try useCase.execute(task, status: .active)
        #expect(task.status == .active)
        #expect(task.completedAt == nil)
    }

    @Test("Archived task cannot transition directly to completed")
    func rejectsInvalidTransition() {
        let repository = FakeTaskRepository()
        let useCase = SetTaskStatusUseCase(taskRepository: repository)
        let task = TaskItem(title: "Шаг", status: .archived)

        #expect(throws: TaskStatusTransitionError.self) {
            try useCase.execute(task, status: .completed)
        }
        #expect(task.status == .archived)
    }

    @Test("Status and completion date roll back when save fails")
    func rollsBackOnFailure() {
        let repository = FakeTaskRepository()
        repository.saveError = FakeRepositoryError.forcedFailure
        let completedAt = Date.now
        let useCase = SetTaskStatusUseCase(taskRepository: repository)
        let task = TaskItem(title: "Шаг", status: .completed, completedAt: completedAt)

        #expect(throws: FakeRepositoryError.self) {
            try useCase.execute(task, status: .archived)
        }
        #expect(task.status == .completed)
        #expect(task.completedAt == completedAt)
    }
}
