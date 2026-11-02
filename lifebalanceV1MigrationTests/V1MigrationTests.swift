import Foundation
import SwiftData
import Testing
@testable import lifebalance

@MainActor
struct V1MigrationTests {
    @Test
    func opensVersionOneStoreWithoutLosingData() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let storeURL = directory.appending(path: "v1.store")
        let oldSchema = Schema(versionedSchema: LifebalanceSchemaV1.self)

        do {
            let oldConfiguration = ModelConfiguration(
                schema: oldSchema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            let oldContainer = try ModelContainer(
                for: oldSchema,
                configurations: oldConfiguration
            )
            let settings = LifebalanceSchemaV1.UserSettings(onboardingStep: .completed)
            let task = LifebalanceSchemaV1.TaskItem(title: "Сохранённая задача")
            oldContainer.mainContext.insert(settings)
            oldContainer.mainContext.insert(task)
            try oldContainer.mainContext.save()
        }

        let currentSchema = Schema(versionedSchema: LifebalanceSchemaV4.self)
        let currentConfiguration = ModelConfiguration(
            schema: currentSchema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let currentContainer = try ModelContainer(
            for: currentSchema,
            migrationPlan: LifebalanceMigrationPlan.self,
            configurations: currentConfiguration
        )
        let settings = try currentContainer.mainContext.fetch(FetchDescriptor<UserSettings>())
        let tasks = try currentContainer.mainContext.fetch(FetchDescriptor<TaskItem>())

        #expect(settings.count == 1)
        #expect(settings.first?.onboardingStep == OnboardingStep.completed)
        #expect(tasks.map(\.title) == ["Сохранённая задача"])
    }
}
