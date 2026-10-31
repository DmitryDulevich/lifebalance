import Testing
@testable import lifebalance

@Suite("Create task")
@MainActor
struct CreateTaskUseCaseTests {
    @Test("Title and note are trimmed before insertion")
    func trimsInput() throws {
        let repository = FakeTaskRepository()
        let useCase = CreateTaskUseCase(taskRepository: repository)
        let input = TaskInput(
            title: "  Prepare release  ",
            note: "  Check metadata  ",
            dueDate: nil,
            important: true,
            urgent: false,
            estimateMinutes: 30,
            lifeArea: nil,
            goal: nil
        )

        let task = try useCase.execute(input)

        #expect(task.title == "Prepare release")
        #expect(task.note == "Check metadata")
        #expect(repository.insertedTasks.count == 1)
        #expect(repository.insertedTasks.first === task)
    }

    @Test("Whitespace-only title is rejected")
    func rejectsEmptyTitle() {
        let repository = FakeTaskRepository()
        let useCase = CreateTaskUseCase(taskRepository: repository)
        let input = TaskInput(
            title: "   \n",
            note: nil,
            dueDate: nil,
            important: nil,
            urgent: nil,
            estimateMinutes: nil,
            lifeArea: nil,
            goal: nil
        )

        #expect(throws: TaskValidationError.self) {
            try useCase.execute(input)
        }
        #expect(repository.insertedTasks.isEmpty)
    }
}
