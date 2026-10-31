import Foundation
import SwiftData

struct AppPersistence {
    let modelContainer: ModelContainer
    let startupErrorMessage: String?

    @MainActor
    static func bootstrap() -> AppPersistence {
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            do {
                let container = try makeContainer(isStoredInMemoryOnly: true)
                try seedUITestDataIfNeeded(in: container)
                return AppPersistence(modelContainer: container, startupErrorMessage: nil)
            } catch {
                AppLogger.error(error, context: "ui_testing.container.create")
            }
        }

        do {
            return AppPersistence(
                modelContainer: try makeContainer(),
                startupErrorMessage: nil
            )
        } catch {
            AppLogger.error(error, context: "storage.container.create")

            do {
                let fallbackContainer = try makeFallbackContainer()
                return AppPersistence(
                    modelContainer: fallbackContainer,
                    startupErrorMessage: "Не удалось открыть локальное хранилище. Ваши данные не удалялись. Полностью закройте приложение и запустите его снова."
                )
            } catch {
                AppLogger.error(error, context: "storage.fallback_container.create")
                fatalError("Failed to create the fallback ModelContainer: \(error)")
            }
        }
    }

    static func makeContainer(isStoredInMemoryOnly: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: LifebalanceSchemaV2.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )

        return try ModelContainer(
            for: schema,
            migrationPlan: LifebalanceMigrationPlan.self,
            configurations: configuration
        )
    }

    private static func makeFallbackContainer() throws -> ModelContainer {
        let schema = Schema([UserSettings.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        return try ModelContainer(for: schema, configurations: configuration)
    }

    @MainActor
    private static func seedUITestDataIfNeeded(in container: ModelContainer) throws {
        guard ProcessInfo.processInfo.arguments.contains("--ui-testing-completed") else {
            return
        }

        let context = container.mainContext
        let settings = UserSettings(onboardingStep: .completed)
        let area = LifeArea(
            name: "Работа",
            icon: "briefcase.fill",
            colorHex: "#5B8DEF",
            order: 0
        )
        let task = TaskItem(
            title: "Тестовая фокус-задача",
            dueDate: .now,
            estimateMinutes: 25,
            lifeArea: area
        )
        context.insert(settings)
        context.insert(area)
        context.insert(task)
        try context.save()
    }
}
