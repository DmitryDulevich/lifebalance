import Foundation
import SwiftData
import Testing
@testable import lifebalance

@MainActor
struct PersistenceTests {
    @Test
    func createsVersionedInMemoryContainer() throws {
        let container = try AppPersistence.makeContainer(isStoredInMemoryOnly: true)
        let repository = SwiftDataUserSettingsRepository(context: container.mainContext)

        let settings = try repository.fetchOrCreate()

        #expect(settings.onboardingStep == OnboardingStep.welcome)
    }

    @Test
    func migrationPlanContainsAllReleasedTransitions() {
        #expect(LifebalanceMigrationPlan.schemas.count == 4)
        #expect(LifebalanceMigrationPlan.stages.count == 3)
        #expect(LifebalanceSchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
        #expect(LifebalanceSchemaV2.versionIdentifier == Schema.Version(2, 0, 0))
        #expect(LifebalanceSchemaV3.versionIdentifier == Schema.Version(3, 0, 0))
        #expect(LifebalanceSchemaV4.versionIdentifier == Schema.Version(4, 0, 0))
    }

    @Test
    func uniqueIdentifierPreventsDuplicateRows() throws {
        let container = try AppPersistence.makeContainer(isStoredInMemoryOnly: true)
        let id = UUID()
        container.mainContext.insert(TaskItem(id: id, title: "Первая версия"))
        container.mainContext.insert(TaskItem(id: id, title: "Вторая версия"))

        try container.mainContext.save()

        let tasks = try container.mainContext.fetch(FetchDescriptor<TaskItem>())
        #expect(tasks.count == 1)
        #expect(tasks.first?.id == id)
    }
}
