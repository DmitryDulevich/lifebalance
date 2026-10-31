import Foundation
import Observation

@Observable
@MainActor
final class TasksViewModel {
    var tasks: [TaskItem] = []
    var lifeAreas: [LifeArea] = []
    var goals: [Goal] = []

    var searchText = ""
    var selectedAreaID: UUID?
    var viewMode = 0 // 0 = list, 1 = matrix

    var errorMessage: String?
    var showTaskForm = false
    var editingTask: TaskItem?

    private let taskRepository: TaskRepository
    private let lifeAreaRepository: LifeAreaRepository
    private let goalRepository: GoalRepository
    private let toggleTaskCompletionUseCase: ToggleTaskCompletionUseCase
    private let updateTaskQuadrantUseCase: UpdateTaskQuadrantUseCase
    private let deleteTaskUseCase: DeleteTaskUseCase

    init(container: AppContainer) {
        self.taskRepository = container.taskRepository
        self.lifeAreaRepository = container.lifeAreaRepository
        self.goalRepository = container.goalRepository
        self.toggleTaskCompletionUseCase = container.toggleTaskCompletionUseCase
        self.updateTaskQuadrantUseCase = container.updateTaskQuadrantUseCase
        self.deleteTaskUseCase = container.deleteTaskUseCase
    }

    func load() {
        do {
            tasks = try taskRepository.fetchAll()
            lifeAreas = try lifeAreaRepository.fetchActiveAreas()
            goals = try goalRepository.fetchActive()
        } catch {
            AppLogger.error(error, context: "tasks.load")
            errorMessage = error.localizedDescription
        }
    }

    var filteredTasks: [TaskItem] {
        tasks.filter { task in
            task.status == .active
                && (selectedAreaID == nil || task.lifeArea?.id == selectedAreaID)
                && (searchText.isEmpty
                    || task.title.localizedCaseInsensitiveContains(searchText)
                    || (task.note?.localizedCaseInsensitiveContains(searchText) ?? false))
        }
    }

    func toggleCompletion(_ task: TaskItem) {
        do {
            try toggleTaskCompletionUseCase.execute(task)
            load()
        } catch {
            AppLogger.error(error, context: "tasks.toggle_completion")
            errorMessage = error.localizedDescription
        }
    }

    func setQuadrant(_ task: TaskItem, important: Bool?, urgent: Bool?) {
        do {
            try updateTaskQuadrantUseCase.execute(task, important: important, urgent: urgent)
            load()
        } catch {
            AppLogger.error(error, context: "tasks.update_quadrant")
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ task: TaskItem) {
        do {
            try deleteTaskUseCase.execute(task)
            load()
        } catch {
            AppLogger.error(error, context: "tasks.delete")
            errorMessage = error.localizedDescription
        }
    }

    func startCreating() {
        editingTask = nil
        showTaskForm = true
    }

    func startEditing(_ task: TaskItem) {
        editingTask = task
        showTaskForm = true
    }
}
