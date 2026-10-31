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
    func migrationPlanStartsAtVersionOne() {
        #expect(LifebalanceMigrationPlan.schemas.count == 1)
        #expect(LifebalanceMigrationPlan.stages.isEmpty)
        #expect(LifebalanceSchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
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
            let settings = UserSettings(onboardingStep: .completed)
            legacyContainer.mainContext.insert(settings)
            try legacyContainer.mainContext.save()
        }

        let versionedSchema = Schema(versionedSchema: LifebalanceSchemaV1.self)
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

        #expect(settings.count == 1)
        #expect(settings.first?.onboardingStep == OnboardingStep.completed)
    }
}
