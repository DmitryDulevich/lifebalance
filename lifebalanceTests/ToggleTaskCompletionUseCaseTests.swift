import Testing
@testable import lifebalance

@Suite("Toggle task completion")
@MainActor
struct ToggleTaskCompletionUseCaseTests {
    @Test("Active task becomes completed")
    func completesTask() throws {
        let repository = FakeTaskRepository()
        let useCase = ToggleTaskCompletionUseCase(taskRepository: repository)
        let task = TaskItem(title: "Write tests")

        try useCase.execute(task)

        #expect(task.status == .completed)
        #expect(task.completedAt != nil)
        #expect(repository.saveCallCount == 1)
    }

    @Test("Completed task becomes active again")
    func reopensTask() throws {
        let repository = FakeTaskRepository()
        let useCase = ToggleTaskCompletionUseCase(taskRepository: repository)
        let task = TaskItem(title: "Write tests", status: .completed, completedAt: .now)

        try useCase.execute(task)

        #expect(task.status == .active)
        #expect(task.completedAt == nil)
        #expect(repository.saveCallCount == 1)
    }

    @Test("Task state is restored when persistence fails")
    func rollsBackOnFailure() {
        let repository = FakeTaskRepository()
        repository.saveError = FakeRepositoryError.forcedFailure
        let useCase = ToggleTaskCompletionUseCase(taskRepository: repository)
        let task = TaskItem(title: "Write tests")

        #expect(throws: FakeRepositoryError.self) {
            try useCase.execute(task)
        }

        #expect(task.status == .active)
        #expect(task.completedAt == nil)
    }
}
