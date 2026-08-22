import Foundation
import Observation

@Observable
@MainActor
final class TodayViewModel {
    struct Content {
        var lifeAreas: [LifeArea]
        var heroTask: TaskItem?
        var overdueTasks: [TaskItem]
        var todayTasks: [TaskItem]
        var doneTasks: [TaskItem]
        var completedCountToday: Int
        var totalCountToday: Int
        var focusMinutesToday: Int
    }

    var state: ViewState<Content> = .idle
    var errorMessage: String?

    private let lifeAreaRepository: LifeAreaRepository
    private let taskRepository: TaskRepository
    private let focusSessionRepository: FocusSessionRepository
    private let toggleTaskCompletionUseCase: ToggleTaskCompletionUseCase

    init(container: AppContainer) {
        self.lifeAreaRepository = container.lifeAreaRepository
        self.taskRepository = container.taskRepository
        self.focusSessionRepository = container.focusSessionRepository
        self.toggleTaskCompletionUseCase = container.toggleTaskCompletionUseCase
    }

    func load() {
        do {
            let areas = try lifeAreaRepository.fetchActiveAreas()
            let allTasks = try taskRepository.fetchAll()
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

            state = .content(Content(
                lifeAreas: areas,
                heroTask: overdue.first ?? today.first,
                overdueTasks: overdue,
                todayTasks: today,
                doneTasks: done,
                completedCountToday: done.count,
                totalCountToday: overdue.count + today.count + done.count,
                focusMinutesToday: focusSeconds / 60
            ))
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func toggleCompletion(_ task: TaskItem) {
        do {
            try toggleTaskCompletionUseCase.execute(task)
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
