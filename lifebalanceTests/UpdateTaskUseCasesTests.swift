import Testing
@testable import lifebalance

@Suite("Update task")
@MainActor
struct UpdateTaskUseCasesTests {
    @Test("All task fields are restored when update persistence fails")
    func updateRollsBackOnFailure() {
        let repository = FakeTaskRepository()
        repository.saveError = FakeRepositoryError.forcedFailure
        let useCase = UpdateTaskUseCase(taskRepository: repository)
        let originalArea = LifeArea(name: "Work", icon: "briefcase", colorHex: "#111111", order: 0)
        let task = TaskItem(
            title: "Original",
            note: "Original note",
            important: false,
            urgent: false,
            estimateMinutes: 15,
            lifeArea: originalArea
        )
        let input = TaskInput(
            title: "Updated",
            note: "Updated note",
            dueDate: .now,
            important: true,
            urgent: true,
            estimateMinutes: 30,
            lifeArea: nil,
            goal: nil
        )

        #expect(throws: FakeRepositoryError.self) {
            try useCase.execute(task, with: input)
        }

        #expect(task.title == "Original")
        #expect(task.note == "Original note")
        #expect(task.dueDate == nil)
        #expect(task.important == false)
        #expect(task.urgent == false)
        #expect(task.estimateMinutes == 15)
        #expect(task.lifeArea === originalArea)
    }

    @Test("Quadrant flags are restored when persistence fails")
    func quadrantRollsBackOnFailure() {
        let repository = FakeTaskRepository()
        repository.saveError = FakeRepositoryError.forcedFailure
        let useCase = UpdateTaskQuadrantUseCase(taskRepository: repository)
        let task = TaskItem(title: "Plan release", important: false, urgent: false)

        #expect(throws: FakeRepositoryError.self) {
            try useCase.execute(task, important: true, urgent: true)
        }

        #expect(task.important == false)
        #expect(task.urgent == false)
    }
}
