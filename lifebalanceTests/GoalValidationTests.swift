import Testing
@testable import lifebalance

@Suite("Goal validation")
@MainActor
struct GoalValidationTests {
    @Test("Title longer than 120 characters is rejected")
    func rejectsLongTitle() {
        let repository = FakeGoalRepository()
        let useCase = CreateGoalUseCase(goalRepository: repository)

        #expect(throws: GoalValidationError.self) {
            try useCase.execute(
                title: String(repeating: "a", count: 121),
                lifeArea: nil,
                targetDate: nil
            )
        }
        #expect(repository.insertedGoals.isEmpty)
    }
}
