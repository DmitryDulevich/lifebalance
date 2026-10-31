import Testing
@testable import lifebalance

@Suite("Balance validation")
@MainActor
struct BalanceValidationTests {
    @Test("Rating outside 1 through 10 is rejected")
    func rejectsOutOfRangeRating() {
        let balanceRepository = FakeBalanceRepository()
        let useCase = AdjustBalanceRatingUseCase(balanceRepository: balanceRepository)
        let area = LifeArea(name: "Health", icon: "heart", colorHex: "#FF0000", order: 0)

        #expect(throws: SaveBalanceSnapshotUseCase.ValidationError.self) {
            try useCase.execute(ratings: [AreaRatingInput(area: area, value: 11, note: nil)])
        }
        #expect(balanceRepository.upsertCallCount == 0)
    }

    @Test("Initial balance uses an idempotent daily upsert")
    func initialBalanceUsesUpsert() throws {
        let balanceRepository = FakeBalanceRepository()
        let settingsRepository = FakeUserSettingsRepository()
        let useCase = SaveBalanceSnapshotUseCase(
            balanceRepository: balanceRepository,
            userSettingsRepository: settingsRepository
        )
        let area = LifeArea(name: "Health", icon: "heart", colorHex: "#FF0000", order: 0)

        try useCase.execute(
            ratings: [AreaRatingInput(area: area, value: 8, note: nil)],
            note: "Initial balance"
        )

        #expect(balanceRepository.savedSnapshotCallCount == 0)
        #expect(balanceRepository.upsertCallCount == 1)
        #expect(balanceRepository.lastNote == "Initial balance")
        #expect(settingsRepository.updatedSteps == [.completed])
    }
}
