import Testing
@testable import lifebalance

@Suite("Manage life areas")
@MainActor
struct ManageLifeAreasUseCaseTests {
    @Test
    func createsNormalizedAreaAtEndOfOrder() throws {
        let repository = FakeLifeAreaRepository()
        repository.activeAreas = makeAreas(count: 3)
        let useCase = ManageLifeAreasUseCase(repository: repository)

        let created = try useCase.create(
            LifeAreaInput(name: "  Хобби  ", icon: "star.fill", colorHex: "FF5A5F")
        )

        #expect(created.name == "Хобби")
        #expect(created.order == 3)
        #expect(repository.activeAreas.count == 4)
    }

    @Test
    func rejectsNameUsedByArchivedArea() {
        let repository = FakeLifeAreaRepository()
        repository.activeAreas = makeAreas(count: 3)
        repository.inactiveAreas = [LifeArea(name: "Хобби", icon: "star.fill", colorHex: "FF5A5F", order: 3, isActive: false)]
        let useCase = ManageLifeAreasUseCase(repository: repository)

        #expect(throws: LifeAreaManagementError.self) {
            try useCase.create(LifeAreaInput(name: "хобби", icon: "star.fill", colorHex: "FF5A5F"))
        }
    }

    @Test
    func keepsAtLeastThreeActiveAreas() {
        let repository = FakeLifeAreaRepository()
        repository.activeAreas = makeAreas(count: 3)
        let useCase = ManageLifeAreasUseCase(repository: repository)

        #expect(throws: LifeAreaManagementError.self) {
            try useCase.setActive(repository.activeAreas[0], isActive: false)
        }
        #expect(repository.activeAreas.allSatisfy { $0.isActive })
    }

    @Test
    func archivesAndRestoresWithoutDeletingArea() throws {
        let repository = FakeLifeAreaRepository()
        repository.activeAreas = makeAreas(count: 4)
        let useCase = ManageLifeAreasUseCase(repository: repository)
        let area = repository.activeAreas[3]

        try useCase.setActive(area, isActive: false)
        #expect(repository.activeAreas.count == 3)
        #expect(repository.inactiveAreas.map(\.id) == [area.id])

        try useCase.setActive(area, isActive: true)
        #expect(repository.activeAreas.count == 4)
        #expect(repository.inactiveAreas.isEmpty)
    }

    @Test
    func rejectsNinthActiveArea() {
        let repository = FakeLifeAreaRepository()
        repository.activeAreas = makeAreas(count: 8)
        let useCase = ManageLifeAreasUseCase(repository: repository)

        #expect(throws: LifeAreaManagementError.self) {
            try useCase.create(LifeAreaInput(name: "Лишняя", icon: "star.fill", colorHex: "FF5A5F"))
        }
    }

    @Test
    func updateRollsBackWhenSaveFails() {
        let repository = FakeLifeAreaRepository()
        let area = makeAreas(count: 3)[0]
        repository.activeAreas = [area] + makeAreas(count: 2, offset: 1)
        repository.saveError = FakeRepositoryError.forcedFailure
        let useCase = ManageLifeAreasUseCase(repository: repository)

        #expect(throws: FakeRepositoryError.self) {
            try useCase.update(
                area,
                with: LifeAreaInput(name: "Новое имя", icon: "star.fill", colorHex: "FF5A5F")
            )
        }
        #expect(area.name == "Сфера 0")
        #expect(area.icon == "circle")
        #expect(area.colorHex == "000000")
    }

    @Test
    func reordersAllActiveAreas() throws {
        let repository = FakeLifeAreaRepository()
        repository.activeAreas = makeAreas(count: 3)
        let useCase = ManageLifeAreasUseCase(repository: repository)
        let reversed = Array(repository.activeAreas.reversed())

        try useCase.reorder(reversed)

        #expect(reversed.map(\.order) == [0, 1, 2])
        #expect(repository.activeAreas.map(\.id) == reversed.map(\.id))
    }

    private func makeAreas(count: Int, offset: Int = 0) -> [LifeArea] {
        (offset..<(offset + count)).map { index in
            LifeArea(
                name: "Сфера \(index)",
                icon: "circle",
                colorHex: "000000",
                order: index
            )
        }
    }
}
