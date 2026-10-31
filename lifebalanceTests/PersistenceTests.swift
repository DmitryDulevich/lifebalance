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
    func migrationPlanContainsVersionOneToVersionTwoTransition() {
        #expect(LifebalanceMigrationPlan.schemas.count == 2)
        #expect(LifebalanceMigrationPlan.stages.count == 1)
        #expect(LifebalanceSchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
        #expect(LifebalanceSchemaV2.versionIdentifier == Schema.Version(2, 0, 0))
    }

    @Test
    func opensLegacyUnversionedStoreWithoutLosingData() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let storeURL = directory.appending(path: "legacy.store")
        let legacySchema = Schema(LifebalanceSchemaV1.models)

        do {
            let legacyConfiguration = ModelConfiguration(
                schema: legacySchema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            let legacyContainer = try ModelContainer(
                for: legacySchema,
                configurations: legacyConfiguration
            )
            let settings = LifebalanceSchemaV1.UserSettings(onboardingStep: .completed)
            let task = LifebalanceSchemaV1.TaskItem(title: "Сохранённая задача")
            legacyContainer.mainContext.insert(settings)
            legacyContainer.mainContext.insert(task)
            try legacyContainer.mainContext.save()
        }

        let versionedSchema = Schema(versionedSchema: LifebalanceSchemaV2.self)
        let versionedConfiguration = ModelConfiguration(
            schema: versionedSchema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let versionedContainer = try ModelContainer(
            for: versionedSchema,
            migrationPlan: LifebalanceMigrationPlan.self,
            configurations: versionedConfiguration
        )
        let settings = try versionedContainer.mainContext.fetch(FetchDescriptor<UserSettings>())
        let tasks = try versionedContainer.mainContext.fetch(FetchDescriptor<TaskItem>())

        #expect(settings.count == 1)
        #expect(settings.first?.onboardingStep == OnboardingStep.completed)
        #expect(tasks.map(\.title) == ["Сохранённая задача"])
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
