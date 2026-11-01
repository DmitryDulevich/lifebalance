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
    let focusNotificationScheduler: FocusNotificationScheduling

    let selectLifeAreasUseCase: SelectLifeAreasUseCase
    let saveBalanceSnapshotUseCase: SaveBalanceSnapshotUseCase
    let advanceOnboardingStepUseCase: AdvanceOnboardingStepUseCase

    let createTaskUseCase: CreateTaskUseCase
    let updateTaskUseCase: UpdateTaskUseCase
    let toggleTaskCompletionUseCase: ToggleTaskCompletionUseCase
    let setTaskStatusUseCase: SetTaskStatusUseCase
    let rescheduleTasksUseCase: RescheduleTasksUseCase
    let updateTaskQuadrantUseCase: UpdateTaskQuadrantUseCase
    let createGoalUseCase: CreateGoalUseCase
    let updateGoalUseCase: UpdateGoalUseCase
    let setGoalStatusUseCase: SetGoalStatusUseCase
    let startFocusSessionUseCase: StartFocusSessionUseCase
    let finishFocusSessionUseCase: FinishFocusSessionUseCase
    let restoreActiveFocusSessionUseCase: RestoreActiveFocusSessionUseCase
    let adjustBalanceRatingUseCase: AdjustBalanceRatingUseCase
    let manageLifeAreasUseCase: ManageLifeAreasUseCase
    let buildAnalyticsUseCase: BuildAnalyticsUseCase

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
        self.focusNotificationScheduler = ProcessInfo.processInfo.arguments.contains("--ui-testing")
            ? NoopFocusNotificationScheduler()
            : LocalFocusNotificationScheduler()

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
        self.setTaskStatusUseCase = SetTaskStatusUseCase(taskRepository: taskRepository)
        self.rescheduleTasksUseCase = RescheduleTasksUseCase(taskRepository: taskRepository)
        self.updateTaskQuadrantUseCase = UpdateTaskQuadrantUseCase(taskRepository: taskRepository)
        self.createGoalUseCase = CreateGoalUseCase(goalRepository: goalRepository)
        self.updateGoalUseCase = UpdateGoalUseCase(goalRepository: goalRepository)
        self.setGoalStatusUseCase = SetGoalStatusUseCase(goalRepository: goalRepository)
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
        self.manageLifeAreasUseCase = ManageLifeAreasUseCase(repository: lifeAreaRepository)
        self.buildAnalyticsUseCase = BuildAnalyticsUseCase(
            focusSessionRepository: focusSessionRepository,
            taskRepository: taskRepository,
            goalRepository: goalRepository,
            balanceRepository: balanceRepository
        )
    }
}

extension AppContainer {
    func makeTasksViewModel() -> TasksViewModel {
        TasksViewModel(
            taskRepository: taskRepository,
            lifeAreaRepository: lifeAreaRepository,
            goalRepository: goalRepository,
            toggleTaskCompletionUseCase: toggleTaskCompletionUseCase,
            updateTaskQuadrantUseCase: updateTaskQuadrantUseCase,
            setTaskStatusUseCase: setTaskStatusUseCase
        )
    }

    func makeTaskFormViewModel(
        lifeAreas: [LifeArea],
        goals: [Goal],
        editingTask: TaskItem?,
        preselectedGoal: Goal? = nil
    ) -> TaskFormViewModel {
        TaskFormViewModel(
            lifeAreas: lifeAreas,
            goals: goals,
            editingTask: editingTask,
            preselectedGoal: preselectedGoal,
            createTaskUseCase: createTaskUseCase,
            updateTaskUseCase: updateTaskUseCase
        )
    }

    func makeGoalDetailViewModel(goal: Goal) -> GoalDetailViewModel {
        GoalDetailViewModel(
            goal: goal,
            toggleTaskCompletionUseCase: toggleTaskCompletionUseCase,
            setTaskStatusUseCase: setTaskStatusUseCase,
            setGoalStatusUseCase: setGoalStatusUseCase
        )
    }

    func makeGoalsViewModel() -> GoalsViewModel {
        GoalsViewModel(
            goalRepository: goalRepository,
            lifeAreaRepository: lifeAreaRepository,
            setGoalStatusUseCase: setGoalStatusUseCase
        )
    }

    func makeGoalFormViewModel(lifeAreas: [LifeArea], editingGoal: Goal?) -> GoalFormViewModel {
        GoalFormViewModel(
            lifeAreas: lifeAreas,
            editingGoal: editingGoal,
            createGoalUseCase: createGoalUseCase,
            updateGoalUseCase: updateGoalUseCase
        )
    }

    func makeTodayViewModel() -> TodayViewModel {
        TodayViewModel(
            lifeAreaRepository: lifeAreaRepository,
            taskRepository: taskRepository,
            goalRepository: goalRepository,
            focusSessionRepository: focusSessionRepository,
            toggleTaskCompletionUseCase: toggleTaskCompletionUseCase,
            rescheduleTasksUseCase: rescheduleTasksUseCase
        )
    }

    func makeBalanceViewModel() -> BalanceViewModel {
        BalanceViewModel(
            lifeAreaRepository: lifeAreaRepository,
            balanceRepository: balanceRepository,
            adjustBalanceRatingUseCase: adjustBalanceRatingUseCase
        )
    }

    func makeAnalyticsViewModel() -> AnalyticsViewModel {
        AnalyticsViewModel(buildAnalyticsUseCase: buildAnalyticsUseCase)
    }

    func makeFocusTimerViewModel(task: TaskItem?, plannedSeconds: Int) -> FocusTimerViewModel {
        FocusTimerViewModel(
            task: task,
            plannedSeconds: plannedSeconds,
            startFocusSessionUseCase: startFocusSessionUseCase,
            finishFocusSessionUseCase: finishFocusSessionUseCase,
            restoreActiveFocusSessionUseCase: restoreActiveFocusSessionUseCase,
            focusSessionRepository: focusSessionRepository,
            notificationScheduler: focusNotificationScheduler
        )
    }

    func makeWelcomeViewModel() -> WelcomeViewModel {
        WelcomeViewModel(advanceOnboardingStepUseCase: advanceOnboardingStepUseCase)
    }

    func makeAreaSelectionViewModel() -> AreaSelectionViewModel {
        AreaSelectionViewModel(selectLifeAreasUseCase: selectLifeAreasUseCase)
    }

    func makeInitialBalanceViewModel() -> InitialBalanceViewModel {
        InitialBalanceViewModel(
            lifeAreaRepository: lifeAreaRepository,
            saveBalanceSnapshotUseCase: saveBalanceSnapshotUseCase,
            advanceOnboardingStepUseCase: advanceOnboardingStepUseCase
        )
    }

    func makeLifeAreasSettingsViewModel() -> LifeAreasSettingsViewModel {
        LifeAreasSettingsViewModel(
            repository: lifeAreaRepository,
            manageLifeAreasUseCase: manageLifeAreasUseCase
        )
    }
}
