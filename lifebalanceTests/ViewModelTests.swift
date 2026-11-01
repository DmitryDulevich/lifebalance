import Foundation
import Testing
@testable import lifebalance

@MainActor
struct ViewModelTests {
    @Test
    func tasksViewModelLoadsFiltersAndRecoversAfterRetry() {
        let taskRepository = FakeTaskRepository()
        let lifeAreaRepository = FakeLifeAreaRepository()
        let goalRepository = FakeGoalRepository()
        let viewModel = makeTasksViewModel(
            taskRepository: taskRepository,
            lifeAreaRepository: lifeAreaRepository,
            goalRepository: goalRepository
        )

        taskRepository.fetchError = FakeRepositoryError.forcedFailure
        viewModel.load()
        #expect(viewModel.errorMessage != nil)

        let work = LifeArea(name: "Работа", icon: "briefcase", colorHex: "#123456", order: 0)
        taskRepository.fetchError = nil
        taskRepository.tasks = [
            TaskItem(title: "Подготовить релиз", note: "App Store", lifeArea: work),
            TaskItem(title: "Купить продукты"),
            TaskItem(title: "Готово", status: .completed)
        ]
        lifeAreaRepository.activeAreas = [work]
        viewModel.load()
        viewModel.searchText = "store"

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.tasks.count == 3)
        #expect(viewModel.filteredTasks.map(\.title) == ["Подготовить релиз"])
    }

    @Test
    func tasksViewModelFiltersByLifecycleStatusAndGoal() {
        let taskRepository = FakeTaskRepository()
        let lifeAreaRepository = FakeLifeAreaRepository()
        let goalRepository = FakeGoalRepository()
        let releaseGoal = Goal(title: "Релиз")
        let healthGoal = Goal(title: "Здоровье")
        goalRepository.activeGoals = [releaseGoal, healthGoal]
        let activeReleaseTask = TaskItem(title: "Сборка", goal: releaseGoal)
        let completedReleaseTask = TaskItem(title: "Дизайн", status: .completed, goal: releaseGoal)
        let completedHealthTask = TaskItem(title: "Тренировка", status: .completed, goal: healthGoal)
        let archivedTask = TaskItem(title: "Старый план", status: .archived, goal: releaseGoal)
        taskRepository.tasks = [activeReleaseTask, completedReleaseTask, completedHealthTask, archivedTask]
        let viewModel = makeTasksViewModel(
            taskRepository: taskRepository,
            lifeAreaRepository: lifeAreaRepository,
            goalRepository: goalRepository
        )

        viewModel.load()
        viewModel.selectedStatus = .completed
        viewModel.selectedGoalID = releaseGoal.id

        #expect(viewModel.filteredTasks.map(\.id) == [completedReleaseTask.id])
        #expect(viewModel.count(for: .active) == 1)
        #expect(viewModel.count(for: .completed) == 2)
        #expect(viewModel.count(for: .archived) == 1)

        viewModel.setStatus(.archived, for: completedReleaseTask)
        #expect(completedReleaseTask.status == .archived)
        #expect(viewModel.count(for: .completed) == 1)
        #expect(viewModel.count(for: .archived) == 2)
    }

    @Test
    func todayViewModelBuildsContentAndExposesLoadFailure() {
        let lifeAreaRepository = FakeLifeAreaRepository()
        let taskRepository = FakeTaskRepository()
        let goalRepository = FakeGoalRepository()
        let focusRepository = FakeFocusSessionRepository()
        let toggleUseCase = ToggleTaskCompletionUseCase(taskRepository: taskRepository)
        let viewModel = TodayViewModel(
            lifeAreaRepository: lifeAreaRepository,
            taskRepository: taskRepository,
            goalRepository: goalRepository,
            focusSessionRepository: focusRepository,
            toggleTaskCompletionUseCase: toggleUseCase,
            rescheduleTasksUseCase: RescheduleTasksUseCase(taskRepository: taskRepository)
        )
        let todayTask = TaskItem(title: "Сегодня", dueDate: .now)
        let doneTask = TaskItem(title: "Готово", status: .completed, completedAt: .now)
        let goal = Goal(title: "Цель")
        goal.tasks = [todayTask]
        goalRepository.activeGoals = [goal]
        taskRepository.tasks = [todayTask, doneTask]
        focusRepository.sessions = [FocusSession(
            startAt: Date.now.addingTimeInterval(-1_800),
            endAt: .now,
            plannedSeconds: 1_800,
            status: .completed
        )]

        viewModel.load()

        guard case .content(let content) = viewModel.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(content.todayTasks.map(\.id) == [todayTask.id])
        #expect(content.completedCountToday == 1)
        #expect(content.focusMinutesToday == 30)
        #expect(content.activeGoals.first?.goal.id == goal.id)
        #expect(content.activeGoals.first?.progress.totalTaskCount == 1)

        taskRepository.fetchError = FakeRepositoryError.forcedFailure
        viewModel.load()
        guard case .error = viewModel.state else {
            Issue.record("Expected error state")
            return
        }
    }

    @Test
    func balanceViewModelLoadsRatingsAndPersistsAdjustment() {
        let area = LifeArea(name: "Здоровье", icon: "heart", colorHex: "#FF0000", order: 0)
        let rating = BalanceRating(value: 6, area: area)
        let snapshot = BalanceSnapshot()
        snapshot.ratings = [rating]
        let areaRepository = FakeLifeAreaRepository()
        areaRepository.activeAreas = [area]
        let balanceRepository = FakeBalanceRepository()
        balanceRepository.latestSnapshot = snapshot
        let viewModel = BalanceViewModel(
            lifeAreaRepository: areaRepository,
            balanceRepository: balanceRepository,
            adjustBalanceRatingUseCase: AdjustBalanceRatingUseCase(balanceRepository: balanceRepository)
        )

        viewModel.load()
        let row = viewModel.rows[0]
        viewModel.adjust(row, delta: 1)

        #expect(viewModel.rows[0].value == 7)
        #expect(viewModel.averageScore == 7)
        #expect(balanceRepository.upsertCallCount == 1)
        #expect(balanceRepository.lastRatings.first?.value == 7)
    }

    @Test
    func taskFormShowsValidationAndThenSaves() {
        let repository = FakeTaskRepository()
        let viewModel = TaskFormViewModel(
            lifeAreas: [],
            goals: [],
            editingTask: nil,
            createTaskUseCase: CreateTaskUseCase(taskRepository: repository),
            updateTaskUseCase: UpdateTaskUseCase(taskRepository: repository)
        )

        viewModel.title = "   "
        #expect(viewModel.save() == false)
        #expect(viewModel.errorMessage != nil)

        viewModel.title = "  Новая задача  "
        #expect(viewModel.save())
        #expect(viewModel.errorMessage == nil)
        #expect(repository.insertedTasks.first?.title == "Новая задача")
    }

    @Test
    func taskFormPreselectsGoalWhenOpenedFromGoalDetails() {
        let repository = FakeTaskRepository()
        let goal = Goal(title: "Выпустить приложение")
        let viewModel = TaskFormViewModel(
            lifeAreas: [],
            goals: [goal],
            editingTask: nil,
            preselectedGoal: goal,
            createTaskUseCase: CreateTaskUseCase(taskRepository: repository),
            updateTaskUseCase: UpdateTaskUseCase(taskRepository: repository)
        )

        viewModel.title = "Подготовить релиз"

        #expect(viewModel.selectedGoalID == goal.id)
        #expect(viewModel.save())
        #expect(repository.insertedTasks.first?.goal?.id == goal.id)
    }

    @Test
    func goalDetailsShowsLinkedTasksAndUpdatesProgress() {
        let repository = FakeTaskRepository()
        let goalRepository = FakeGoalRepository()
        let activeTask = TaskItem(title: "Реализовать")
        let completedTask = TaskItem(title: "Спроектировать", status: .completed, completedAt: .now)
        let goal = Goal(title: "Выпустить приложение")
        goal.tasks = [completedTask, activeTask]
        let viewModel = GoalDetailViewModel(
            goal: goal,
            toggleTaskCompletionUseCase: ToggleTaskCompletionUseCase(taskRepository: repository),
            deleteTaskUseCase: DeleteTaskUseCase(taskRepository: repository),
            setGoalStatusUseCase: SetGoalStatusUseCase(goalRepository: goalRepository)
        )

        #expect(viewModel.tasks.map(\.id).first == activeTask.id)
        #expect(viewModel.progress.completedTaskCount == 1)
        #expect(viewModel.progress.totalTaskCount == 2)

        viewModel.toggleCompletion(activeTask)

        #expect(viewModel.progress.completedTaskCount == 2)
        #expect(viewModel.progress.percentage == 100)
        #expect(viewModel.showCompletionPrompt)

        viewModel.completeGoal()

        #expect(goal.status == .completed)
        #expect(!viewModel.showCompletionPrompt)
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func goalDetailsEditsAndDeletesLinkedTask() {
        let taskRepository = FakeTaskRepository()
        let goalRepository = FakeGoalRepository()
        let firstTask = TaskItem(title: "Первый шаг", status: .completed)
        let secondTask = TaskItem(title: "Второй шаг")
        let goal = Goal(title: "Цель")
        goal.tasks = [firstTask, secondTask]
        taskRepository.tasks = [firstTask, secondTask]
        let viewModel = GoalDetailViewModel(
            goal: goal,
            toggleTaskCompletionUseCase: ToggleTaskCompletionUseCase(taskRepository: taskRepository),
            deleteTaskUseCase: DeleteTaskUseCase(taskRepository: taskRepository),
            setGoalStatusUseCase: SetGoalStatusUseCase(goalRepository: goalRepository)
        )

        viewModel.startEditing(secondTask)
        #expect(viewModel.showTaskForm)
        #expect(viewModel.editingTask?.id == secondTask.id)

        viewModel.delete(firstTask)

        #expect(taskRepository.deletedTasks.map(\.id) == [firstTask.id])
        #expect(viewModel.tasks.map(\.id) == [secondTask.id])
        #expect(viewModel.progress.completedTaskCount == 0)
        #expect(viewModel.progress.totalTaskCount == 1)
    }

    @Test
    func archivedGoalDetailsAreReadOnly() {
        let taskRepository = FakeTaskRepository()
        let goalRepository = FakeGoalRepository()
        let task = TaskItem(title: "Шаг")
        let goal = Goal(title: "Архив", status: .archived)
        goal.tasks = [task]
        let viewModel = GoalDetailViewModel(
            goal: goal,
            toggleTaskCompletionUseCase: ToggleTaskCompletionUseCase(taskRepository: taskRepository),
            deleteTaskUseCase: DeleteTaskUseCase(taskRepository: taskRepository),
            setGoalStatusUseCase: SetGoalStatusUseCase(goalRepository: goalRepository)
        )

        viewModel.startCreatingTask()
        viewModel.startEditing(task)
        viewModel.toggleCompletion(task)
        viewModel.delete(task)

        #expect(!viewModel.canAddTask)
        #expect(!viewModel.canModifyTasks)
        #expect(!viewModel.showTaskForm)
        #expect(task.status == .active)
        #expect(taskRepository.deletedTasks.isEmpty)
    }

    @Test
    func welcomeViewModelRecoversAfterFailedStart() {
        let repository = FakeUserSettingsRepository()
        let viewModel = WelcomeViewModel(
            advanceOnboardingStepUseCase: AdvanceOnboardingStepUseCase(userSettingsRepository: repository)
        )

        repository.updateError = FakeRepositoryError.forcedFailure
        #expect(viewModel.start() == false)
        #expect(viewModel.errorMessage != nil)

        repository.updateError = nil
        #expect(viewModel.start())
        #expect(viewModel.errorMessage == nil)
        #expect(repository.settings.onboardingStep == .areaSelection)
    }

    @Test
    func focusViewModelStartsPausesAndFinishesSession() {
        let focusRepository = FakeFocusSessionRepository()
        let taskRepository = FakeTaskRepository()
        let startUseCase = StartFocusSessionUseCase(focusSessionRepository: focusRepository)
        let finishUseCase = FinishFocusSessionUseCase(
            focusSessionRepository: focusRepository,
            taskRepository: taskRepository
        )
        let restoreUseCase = RestoreActiveFocusSessionUseCase(
            focusSessionRepository: focusRepository,
            finishFocusSessionUseCase: finishUseCase
        )
        let notificationScheduler = FakeFocusNotificationScheduler()
        let viewModel = FocusTimerViewModel(
            task: nil,
            plannedSeconds: 1_500,
            startFocusSessionUseCase: startUseCase,
            finishFocusSessionUseCase: finishUseCase,
            restoreActiveFocusSessionUseCase: restoreUseCase,
            focusSessionRepository: focusRepository,
            notificationScheduler: notificationScheduler
        )

        viewModel.start()
        #expect(viewModel.session?.status == .running)
        #expect(notificationScheduler.scheduledNotifications.count == 1)

        viewModel.togglePause()
        #expect(viewModel.session?.status == .paused)
        #expect(notificationScheduler.cancelledSessionIDs.count == 1)

        viewModel.togglePause()
        #expect(viewModel.session?.status == .running)
        #expect(notificationScheduler.scheduledNotifications.count == 2)

        #expect(viewModel.finish())
        #expect(viewModel.session?.status == .completed)
        #expect(viewModel.didFinish)
        #expect(viewModel.displaySeconds == 0)
        #expect(notificationScheduler.cancelledSessionIDs.count == 2)
    }

    @Test
    func focusViewModelFinishesExpiredSessionAfterReturningToForeground() {
        let focusRepository = FakeFocusSessionRepository()
        let taskRepository = FakeTaskRepository()
        let notificationScheduler = FakeFocusNotificationScheduler()
        let finishUseCase = FinishFocusSessionUseCase(
            focusSessionRepository: focusRepository,
            taskRepository: taskRepository
        )
        let viewModel = FocusTimerViewModel(
            task: nil,
            plannedSeconds: 60,
            startFocusSessionUseCase: StartFocusSessionUseCase(focusSessionRepository: focusRepository),
            finishFocusSessionUseCase: finishUseCase,
            restoreActiveFocusSessionUseCase: RestoreActiveFocusSessionUseCase(
                focusSessionRepository: focusRepository,
                finishFocusSessionUseCase: finishUseCase
            ),
            focusSessionRepository: focusRepository,
            notificationScheduler: notificationScheduler
        )

        viewModel.start()
        viewModel.session?.startAt = Date.now.addingTimeInterval(-120)
        viewModel.applicationDidBecomeActive()

        #expect(viewModel.didFinish)
        #expect(viewModel.displaySeconds == 0)
        #expect(viewModel.session?.status == .completed)
        #expect(notificationScheduler.cancelledSessionIDs.last == viewModel.session?.id)
    }

    @Test
    func focusViewModelRollsBackPauseWhenPersistenceFails() {
        let focusRepository = FakeFocusSessionRepository()
        let taskRepository = FakeTaskRepository()
        let notificationScheduler = FakeFocusNotificationScheduler()
        let finishUseCase = FinishFocusSessionUseCase(
            focusSessionRepository: focusRepository,
            taskRepository: taskRepository
        )
        let viewModel = FocusTimerViewModel(
            task: nil,
            plannedSeconds: 300,
            startFocusSessionUseCase: StartFocusSessionUseCase(focusSessionRepository: focusRepository),
            finishFocusSessionUseCase: finishUseCase,
            restoreActiveFocusSessionUseCase: RestoreActiveFocusSessionUseCase(
                focusSessionRepository: focusRepository,
                finishFocusSessionUseCase: finishUseCase
            ),
            focusSessionRepository: focusRepository,
            notificationScheduler: notificationScheduler
        )
        viewModel.start()
        focusRepository.saveError = FakeRepositoryError.forcedFailure

        viewModel.togglePause()

        #expect(viewModel.session?.status == .running)
        #expect(viewModel.session?.pausedAt == nil)
        #expect(viewModel.errorMessage != nil)
        #expect(notificationScheduler.scheduledNotifications.count == 2)
    }

    @Test
    func lifeAreasSettingsViewModelAddsAndArchivesArea() {
        let repository = FakeLifeAreaRepository()
        repository.activeAreas = (0..<3).map {
            LifeArea(name: "Сфера \($0)", icon: "circle", colorHex: "000000", order: $0)
        }
        let viewModel = LifeAreasSettingsViewModel(
            repository: repository,
            manageLifeAreasUseCase: ManageLifeAreasUseCase(repository: repository)
        )

        viewModel.load()
        viewModel.startAdding()
        viewModel.formName = "Хобби"
        #expect(viewModel.saveForm())
        #expect(viewModel.activeAreas.count == 4)

        let created = viewModel.activeAreas.first { $0.name == "Хобби" }
        #expect(created != nil)
        if let created {
            viewModel.archive(created)
        }
        #expect(viewModel.activeAreas.count == 3)
        #expect(viewModel.archivedAreas.map(\.name) == ["Хобби"])
    }

    @Test
    func goalsViewModelFiltersAndChangesLifecycleStatus() {
        let goalRepository = FakeGoalRepository()
        let active = Goal(title: "Активная")
        let paused = Goal(title: "На паузе", status: .paused)
        goalRepository.activeGoals = [active]
        goalRepository.otherGoals = [paused]
        let areaRepository = FakeLifeAreaRepository()
        let viewModel = GoalsViewModel(
            goalRepository: goalRepository,
            lifeAreaRepository: areaRepository,
            setGoalStatusUseCase: SetGoalStatusUseCase(goalRepository: goalRepository)
        )

        viewModel.load()
        #expect(viewModel.filteredGoals.map(\.id) == [active.id])

        viewModel.selectedStatus = .paused
        #expect(viewModel.filteredGoals.map(\.id) == [paused.id])
        viewModel.setStatus(.active, for: paused)

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.count(for: .active) == 2)
        #expect(viewModel.count(for: .paused) == 0)
    }

    @Test
    func goalFormPrepopulatesAndUpdatesExistingGoal() {
        let repository = FakeGoalRepository()
        let area = LifeArea(name: "Работа", icon: "briefcase", colorHex: "000000", order: 0)
        let targetDate = Date(timeIntervalSince1970: 20_000)
        let goal = Goal(title: "Исходная", targetDate: targetDate, lifeArea: area)
        repository.activeGoals = [goal]
        let viewModel = GoalFormViewModel(
            lifeAreas: [area],
            editingGoal: goal,
            createGoalUseCase: CreateGoalUseCase(goalRepository: repository),
            updateGoalUseCase: UpdateGoalUseCase(goalRepository: repository)
        )

        #expect(viewModel.isEditing)
        #expect(viewModel.title == "Исходная")
        #expect(viewModel.selectedAreaID == area.id)
        #expect(viewModel.hasTargetDate)

        viewModel.title = "  Обновлённая  "
        viewModel.hasTargetDate = false
        #expect(viewModel.save())
        #expect(goal.title == "Обновлённая")
        #expect(goal.targetDate == nil)
    }

    private func makeTasksViewModel(
        taskRepository: FakeTaskRepository,
        lifeAreaRepository: FakeLifeAreaRepository,
        goalRepository: FakeGoalRepository
    ) -> TasksViewModel {
        TasksViewModel(
            taskRepository: taskRepository,
            lifeAreaRepository: lifeAreaRepository,
            goalRepository: goalRepository,
            toggleTaskCompletionUseCase: ToggleTaskCompletionUseCase(taskRepository: taskRepository),
            updateTaskQuadrantUseCase: UpdateTaskQuadrantUseCase(taskRepository: taskRepository),
            setTaskStatusUseCase: SetTaskStatusUseCase(taskRepository: taskRepository)
        )
    }
}
