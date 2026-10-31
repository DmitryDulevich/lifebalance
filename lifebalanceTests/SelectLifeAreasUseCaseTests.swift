import Testing
@testable import lifebalance

@Suite("Select life areas")
@MainActor
struct SelectLifeAreasUseCaseTests {
    @Test("Three selected areas are inserted in display order")
    func insertsAreasAndAdvancesOnboarding() throws {
        let lifeAreaRepository = FakeLifeAreaRepository()
        let settingsRepository = FakeUserSettingsRepository()
        let useCase = SelectLifeAreasUseCase(
            lifeAreaRepository: lifeAreaRepository,
            userSettingsRepository: settingsRepository
        )
        let drafts = [
            LifeAreaDraft(name: "Health", icon: "heart", colorHex: "#FF0000"),
            LifeAreaDraft(name: "Work", icon: "briefcase", colorHex: "#00FF00"),
            LifeAreaDraft(name: "Family", icon: "person.2", colorHex: "#0000FF")
        ]

        try useCase.execute(drafts)

        let inserted = lifeAreaRepository.insertedBatches.first
        #expect(inserted?.map(\.name) == ["Health", "Work", "Family"])
        #expect(inserted?.map(\.order) == [0, 1, 2])
        #expect(settingsRepository.updatedSteps == [.initialBalance])
    }

    @Test("Fewer than three areas are rejected")
    func rejectsTooFewAreas() {
        let lifeAreaRepository = FakeLifeAreaRepository()
        let settingsRepository = FakeUserSettingsRepository()
        let useCase = SelectLifeAreasUseCase(
            lifeAreaRepository: lifeAreaRepository,
            userSettingsRepository: settingsRepository
        )
        let drafts = [
            LifeAreaDraft(name: "Health", icon: "heart", colorHex: "#FF0000"),
            LifeAreaDraft(name: "Work", icon: "briefcase", colorHex: "#00FF00")
        ]

        #expect(throws: SelectLifeAreasUseCase.ValidationError.self) {
            try useCase.execute(drafts)
        }
        #expect(lifeAreaRepository.insertedBatches.isEmpty)
        #expect(settingsRepository.updatedSteps.isEmpty)
    }

    @Test("More than eight areas are rejected")
    func rejectsTooManyAreas() {
        let lifeAreaRepository = FakeLifeAreaRepository()
        let settingsRepository = FakeUserSettingsRepository()
        let useCase = SelectLifeAreasUseCase(
            lifeAreaRepository: lifeAreaRepository,
            userSettingsRepository: settingsRepository
        )
        let drafts = (0..<9).map {
            LifeAreaDraft(name: "Area \($0)", icon: "circle", colorHex: "#000000")
        }

        #expect(throws: SelectLifeAreasUseCase.ValidationError.self) {
            try useCase.execute(drafts)
        }
        #expect(lifeAreaRepository.insertedBatches.isEmpty)
        #expect(settingsRepository.updatedSteps.isEmpty)
    }

    @Test("Retry after settings failure does not insert duplicate areas")
    func retryIsIdempotent() throws {
        let lifeAreaRepository = FakeLifeAreaRepository()
        let settingsRepository = FakeUserSettingsRepository()
        settingsRepository.updateError = FakeRepositoryError.forcedFailure
        let useCase = SelectLifeAreasUseCase(
            lifeAreaRepository: lifeAreaRepository,
            userSettingsRepository: settingsRepository
        )
        let drafts = [
            LifeAreaDraft(name: "Health", icon: "heart", colorHex: "#FF0000"),
            LifeAreaDraft(name: "Work", icon: "briefcase", colorHex: "#00FF00"),
            LifeAreaDraft(name: "Family", icon: "person.2", colorHex: "#0000FF")
        ]

        #expect(throws: FakeRepositoryError.self) {
            try useCase.execute(drafts)
        }
        #expect(lifeAreaRepository.insertedBatches.count == 1)

        settingsRepository.updateError = nil
        try useCase.execute(drafts)

        #expect(lifeAreaRepository.insertedBatches.count == 1)
        #expect(settingsRepository.updatedSteps == [.initialBalance])
    }

    @Test("Duplicate area names are rejected case-insensitively")
    func rejectsDuplicateNames() {
        let lifeAreaRepository = FakeLifeAreaRepository()
        let settingsRepository = FakeUserSettingsRepository()
        let useCase = SelectLifeAreasUseCase(
            lifeAreaRepository: lifeAreaRepository,
            userSettingsRepository: settingsRepository
        )
        let drafts = [
            LifeAreaDraft(name: "Health", icon: "heart", colorHex: "#FF0000"),
            LifeAreaDraft(name: "health", icon: "heart", colorHex: "#00FF00"),
            LifeAreaDraft(name: "Family", icon: "person.2", colorHex: "#0000FF")
        ]

        #expect(throws: SelectLifeAreasUseCase.ValidationError.self) {
            try useCase.execute(drafts)
        }
        #expect(lifeAreaRepository.insertedBatches.isEmpty)
    }
}
