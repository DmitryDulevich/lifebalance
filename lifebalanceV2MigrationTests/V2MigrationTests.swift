import Foundation
import SwiftData
import Testing
@testable import lifebalance

@MainActor
struct V2MigrationTests {
    @Test
    func migratesStoreAndKeepsNewHistoricalFieldsOptional() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let storeURL = directory.appending(path: "v2.store")
        let oldSchema = Schema(versionedSchema: LifebalanceSchemaV2.self)

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
            let goal = LifebalanceSchemaV2.Goal(title: "Старая цель")
            let task = LifebalanceSchemaV2.TaskItem(title: "Старая задача", goal: goal)
            let session = LifebalanceSchemaV2.FocusSession(
                plannedSeconds: 1_500,
                status: .completed,
                task: task
            )
            oldContainer.mainContext.insert(goal)
            oldContainer.mainContext.insert(task)
            oldContainer.mainContext.insert(session)
            try oldContainer.mainContext.save()
        }

        let currentSchema = Schema(versionedSchema: LifebalanceSchemaV3.self)
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

        let goals = try currentContainer.mainContext.fetch(FetchDescriptor<Goal>())
        let sessions = try currentContainer.mainContext.fetch(FetchDescriptor<FocusSession>())
        let events = try currentContainer.mainContext.fetch(FetchDescriptor<GoalStatusEvent>())

        #expect(goals.map(\.title) == ["Старая цель"])
        #expect(events.isEmpty)
        #expect(sessions.first?.taskTitleSnapshot == nil)
        #expect(sessions.first?.task?.title == "Старая задача")
    }
}
