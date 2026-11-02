import Foundation
import Observation

@Observable
@MainActor
final class TodayViewModel {
    struct GoalSummary: Identifiable {
        let goal: Goal
        let progress: GoalProgress

        var id: UUID { goal.id }
    }

    struct Content {
        var lifeAreas: [LifeArea]
        var heroTask: TaskItem?
        var overdueTasks: [TaskItem]
        var todayTasks: [TaskItem]
        var doneTasks: [TaskItem]
        var completedCountToday: Int
        var totalCountToday: Int
        var focusMinutesToday: Int
        var activeGoals: [GoalSummary]
    }

    var state: ViewState<Content> = .idle
    var errorMessage: String?

    private let lifeAreaRepository: LifeAreaRepository
    private let taskRepository: TaskRepository
    private let goalRepository: GoalRepository
    private let focusSessionRepository: FocusSessionRepository
    private let toggleTaskCompletionUseCase: ToggleTaskCompletionUseCase
    private let rescheduleTasksUseCase: RescheduleTasksUseCase
    private let generateRecurringTasksUseCase: GenerateRecurringTasksUseCase?
    private let refreshRemindersUseCase: RefreshRemindersUseCase?

    init(
        lifeAreaRepository: LifeAreaRepository,
        taskRepository: TaskRepository,
        goalRepository: GoalRepository,
        focusSessionRepository: FocusSessionRepository,
        toggleTaskCompletionUseCase: ToggleTaskCompletionUseCase,
        rescheduleTasksUseCase: RescheduleTasksUseCase,
        generateRecurringTasksUseCase: GenerateRecurringTasksUseCase? = nil,
        refreshRemindersUseCase: RefreshRemindersUseCase? = nil
    ) {
        self.lifeAreaRepository = lifeAreaRepository
        self.taskRepository = taskRepository
        self.goalRepository = goalRepository
        self.focusSessionRepository = focusSessionRepository
        self.toggleTaskCompletionUseCase = toggleTaskCompletionUseCase
        self.rescheduleTasksUseCase = rescheduleTasksUseCase
        self.generateRecurringTasksUseCase = generateRecurringTasksUseCase
        self.refreshRemindersUseCase = refreshRemindersUseCase
    }

    func load() {
        state = .loading
        errorMessage = nil
        do {
            try generateRecurringTasksUseCase?.execute()
            let areas = try lifeAreaRepository.fetchActiveAreas()
            let allTasks = try taskRepository.fetchAll()
            let goals = try goalRepository.fetchActive()
            let sessions = try focusSessionRepository.fetchAll()

            let calendar = Calendar.current
            let now = Date.now
            let startOfToday = calendar.startOfDay(for: now)

            let activeTasks = allTasks.filter { $0.status == .active }

            let overdue = activeTasks
                .filter { ($0.dueDate ?? .distantFuture) < startOfToday }
                .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }

            let today = activeTasks
                .filter { calendar.isDateInToday($0.dueDate ?? .distantPast) }
                .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }

            let done = allTasks
                .filter { $0.status == .completed && calendar.isDateInToday($0.completedAt ?? .distantPast) }

            let focusSeconds = sessions
                .filter { $0.status == .completed && calendar.isDateInToday($0.startAt) }
                .reduce(0) { partial, session -> Int in
                    let end = session.endAt ?? session.startAt
                    let elapsed = max(0, Int(end.timeIntervalSince(session.startAt)) - session.pausedSeconds)
                    return partial + elapsed
                }

            let content = Content(
                lifeAreas: areas,
                heroTask: overdue.first ?? today.first,
                overdueTasks: overdue,
                todayTasks: today,
                doneTasks: done,
                completedCountToday: done.count,
                totalCountToday: overdue.count + today.count + done.count,
                focusMinutesToday: focusSeconds / 60,
                activeGoals: goals.map {
                    GoalSummary(goal: $0, progress: GoalProgressCalculator.summary(for: $0))
                }
            )
            state = .content(content)
            let overdueIDs = Set(overdue.map(\.id))
            TodayWidgetSnapshotStore.save(TodayWidgetSnapshot(
                updatedAt: now,
                completedCount: content.completedCountToday,
                totalCount: content.totalCountToday,
                focusMinutes: content.focusMinutesToday,
                tasks: Array((overdue + today).prefix(3)).map {
                    TodayWidgetSnapshot.Task(
                        title: $0.title,
                        isOverdue: overdueIDs.contains($0.id)
                    )
                }
            ))
            Task { try? await refreshRemindersUseCase?.execute() }
        } catch {
            AppLogger.error(error, context: "today.load")
            state = .error(error.localizedDescription)
        }
    }

    func toggleCompletion(_ task: TaskItem) {
        do {
            try toggleTaskCompletionUseCase.execute(task)
            load()
        } catch {
            AppLogger.error(error, context: "today.toggle_completion")
            errorMessage = error.localizedDescription
        }
    }

    func moveToTomorrow(_ task: TaskItem) {
        rescheduleToTomorrow([task])
    }

    func moveAllOverdueToTomorrow() {
        guard case .content(let content) = state else { return }
        rescheduleToTomorrow(content.overdueTasks)
    }

    private func rescheduleToTomorrow(_ tasks: [TaskItem]) {
        do {
            try rescheduleTasksUseCase.moveToTomorrow(tasks)
            load()
        } catch {
            AppLogger.error(error, context: "today.reschedule")
            errorMessage = error.localizedDescription
        }
    }
}
