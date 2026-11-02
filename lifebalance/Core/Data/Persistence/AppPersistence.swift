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
                StorageDiagnostics.markReady()
                return AppPersistence(modelContainer: container, startupErrorMessage: nil)
            } catch {
                AppLogger.error(error, context: "ui_testing.container.create")
            }
        }

        do {
            let persistence = AppPersistence(
                modelContainer: try makeContainer(),
                startupErrorMessage: nil
            )
            StorageDiagnostics.markReady()
            AppLogger.info("storage.container.ready", metadata: ["schema": "4.0.0"])
            return persistence
        } catch {
            let originalError = error
            let incidentID = AppLogger.error(error, context: "storage.container.create")

            do {
                let fallbackContainer = try makeFallbackContainer()
                StorageDiagnostics.markFallback(after: originalError)
                AppLogger.notice(
                    "storage.container.fallback",
                    metadata: ["incident": String(incidentID.uuidString.prefix(8))]
                )
                return AppPersistence(
                    modelContainer: fallbackContainer,
                    startupErrorMessage: String(
                        localized: "Не удалось открыть локальное хранилище. Ваши данные не удалялись. Полностью закройте приложение и запустите его снова. Код диагностики: \(incidentID.uuidString.prefix(8))."
                    )
                )
            } catch {
                StorageDiagnostics.markFailed(after: error)
                AppLogger.critical(error, context: "storage.fallback_container.create")
                fatalError("Failed to create the fallback ModelContainer: \(error)")
            }
        }
    }

    static func makeContainer(isStoredInMemoryOnly: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: LifebalanceSchemaV4.self)
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
        let healthArea = LifeArea(
            name: "Здоровье",
            icon: "heart.fill",
            colorHex: "#029E72",
            order: 1
        )
        let learningArea = LifeArea(
            name: "Обучение",
            icon: "book.fill",
            colorHex: "#A58A07",
            order: 2
        )
        let goal = Goal(
            title: "Тестовая цель",
            targetDate: Calendar.current.date(byAdding: .month, value: 1, to: .now),
            lifeArea: area
        )
        let task = TaskItem(
            title: "Тестовая фокус-задача",
            dueDate: .now,
            estimateMinutes: 25,
            lifeArea: area,
            goal: goal
        )
        let overdueTask = TaskItem(
            title: "Просроченная задача",
            dueDate: Calendar.current.date(byAdding: .day, value: -1, to: .now),
            estimateMinutes: 15,
            lifeArea: area
        )
        let focusSession = FocusSession(
            startAt: Date.now.addingTimeInterval(-1_500),
            endAt: .now,
            plannedSeconds: 1_500,
            status: .completed,
            task: task
        )
        let balanceSnapshot = BalanceSnapshot(createdAt: Date.now.addingTimeInterval(-3_600))
        let balanceRating = BalanceRating(
            value: 7,
            area: area,
            snapshot: balanceSnapshot
        )
        context.insert(settings)
        context.insert(area)
        context.insert(healthArea)
        context.insert(learningArea)
        context.insert(goal)
        context.insert(task)
        context.insert(overdueTask)
        context.insert(focusSession)
        context.insert(balanceSnapshot)
        context.insert(balanceRating)
        try context.save()
    }
}
