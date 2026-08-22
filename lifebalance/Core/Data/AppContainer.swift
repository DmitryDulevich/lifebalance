import Foundation
import SwiftData

@MainActor
final class AppContainer {
    let lifeAreaRepository: LifeAreaRepository
    let userSettingsRepository: UserSettingsRepository
    let balanceRepository: BalanceRepository
    let taskRepository: TaskRepository
    let goalRepository: GoalRepository
    let focusSessionRepository: FocusSessionRepository

    let selectLifeAreasUseCase: SelectLifeAreasUseCase
    let saveBalanceSnapshotUseCase: SaveBalanceSnapshotUseCase
    let advanceOnboardingStepUseCase: AdvanceOnboardingStepUseCase

    let createTaskUseCase: CreateTaskUseCase
    let updateTaskUseCase: UpdateTaskUseCase
    let toggleTaskCompletionUseCase: ToggleTaskCompletionUseCase
    let updateTaskQuadrantUseCase: UpdateTaskQuadrantUseCase
    let deleteTaskUseCase: DeleteTaskUseCase
    let createGoalUseCase: CreateGoalUseCase
    let startFocusSessionUseCase: StartFocusSessionUseCase
    let finishFocusSessionUseCase: FinishFocusSessionUseCase
    let restoreActiveFocusSessionUseCase: RestoreActiveFocusSessionUseCase
    let adjustBalanceRatingUseCase: AdjustBalanceRatingUseCase

    init(modelContext: ModelContext) {
        let lifeAreaRepository = SwiftDataLifeAreaRepository(context: modelContext)
        let userSettingsRepository = SwiftDataUserSettingsRepository(context: modelContext)
        let balanceRepository = SwiftDataBalanceRepository(context: modelContext)
        let taskRepository = SwiftDataTaskRepository(context: modelContext)
        let goalRepository = SwiftDataGoalRepository(context: modelContext)
        let focusSessionRepository = SwiftDataFocusSessionRepository(context: modelContext)

        self.lifeAreaRepository = lifeAreaRepository
        self.userSettingsRepository = userSettingsRepository
        self.balanceRepository = balanceRepository
        self.taskRepository = taskRepository
        self.goalRepository = goalRepository
        self.focusSessionRepository = focusSessionRepository

        self.selectLifeAreasUseCase = SelectLifeAreasUseCase(
            lifeAreaRepository: lifeAreaRepository,
            userSettingsRepository: userSettingsRepository
        )
        self.saveBalanceSnapshotUseCase = SaveBalanceSnapshotUseCase(
            balanceRepository: balanceRepository,
            userSettingsRepository: userSettingsRepository
        )
        self.advanceOnboardingStepUseCase = AdvanceOnboardingStepUseCase(
            userSettingsRepository: userSettingsRepository
        )

        self.createTaskUseCase = CreateTaskUseCase(taskRepository: taskRepository)
        self.updateTaskUseCase = UpdateTaskUseCase(taskRepository: taskRepository)
        self.toggleTaskCompletionUseCase = ToggleTaskCompletionUseCase(taskRepository: taskRepository)
        self.updateTaskQuadrantUseCase = UpdateTaskQuadrantUseCase(taskRepository: taskRepository)
        self.deleteTaskUseCase = DeleteTaskUseCase(taskRepository: taskRepository)
        self.createGoalUseCase = CreateGoalUseCase(goalRepository: goalRepository)
        self.startFocusSessionUseCase = StartFocusSessionUseCase(focusSessionRepository: focusSessionRepository)
        let finishFocusSessionUseCase = FinishFocusSessionUseCase(
            focusSessionRepository: focusSessionRepository,
            taskRepository: taskRepository
        )
        self.finishFocusSessionUseCase = finishFocusSessionUseCase
        self.restoreActiveFocusSessionUseCase = RestoreActiveFocusSessionUseCase(
            focusSessionRepository: focusSessionRepository,
            finishFocusSessionUseCase: finishFocusSessionUseCase
        )
        self.adjustBalanceRatingUseCase = AdjustBalanceRatingUseCase(balanceRepository: balanceRepository)
    }
}
