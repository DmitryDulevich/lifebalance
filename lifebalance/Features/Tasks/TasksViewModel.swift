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
    var selectedGoalID: UUID?
    var selectedStatus: TaskStatus = .active
    var viewMode = 0 // 0 = list, 1 = matrix

    var errorMessage: String?
    var showTaskForm = false
    var editingTask: TaskItem?

    private let taskRepository: TaskRepository
    private let lifeAreaRepository: LifeAreaRepository
    private let goalRepository: GoalRepository
    private let toggleTaskCompletionUseCase: ToggleTaskCompletionUseCase
    private let updateTaskQuadrantUseCase: UpdateTaskQuadrantUseCase
    private let setTaskStatusUseCase: SetTaskStatusUseCase
    private let generateRecurringTasksUseCase: GenerateRecurringTasksUseCase?

    init(
        taskRepository: TaskRepository,
        lifeAreaRepository: LifeAreaRepository,
        goalRepository: GoalRepository,
        toggleTaskCompletionUseCase: ToggleTaskCompletionUseCase,
        updateTaskQuadrantUseCase: UpdateTaskQuadrantUseCase,
        setTaskStatusUseCase: SetTaskStatusUseCase,
        generateRecurringTasksUseCase: GenerateRecurringTasksUseCase? = nil
    ) {
        self.taskRepository = taskRepository
        self.lifeAreaRepository = lifeAreaRepository
        self.goalRepository = goalRepository
        self.toggleTaskCompletionUseCase = toggleTaskCompletionUseCase
        self.updateTaskQuadrantUseCase = updateTaskQuadrantUseCase
        self.setTaskStatusUseCase = setTaskStatusUseCase
        self.generateRecurringTasksUseCase = generateRecurringTasksUseCase
    }

    func load() {
        do {
            try generateRecurringTasksUseCase?.execute()
            tasks = try taskRepository.fetchAll()
            lifeAreas = try lifeAreaRepository.fetchActiveAreas()
            goals = try goalRepository.fetchAll()
            errorMessage = nil
        } catch {
            AppLogger.error(error, context: "tasks.load")
            errorMessage = error.localizedDescription
        }
    }

    var filteredTasks: [TaskItem] {
        tasks.filter { task in
            task.status == selectedStatus
                && (selectedAreaID == nil || task.lifeArea?.id == selectedAreaID)
                && (selectedGoalID == nil || task.goal?.id == selectedGoalID)
                && (searchText.isEmpty
                    || task.title.localizedCaseInsensitiveContains(searchText)
                    || (task.note?.localizedCaseInsensitiveContains(searchText) ?? false))
        }
    }

    var formGoals: [Goal] {
        var result = goals.filter { $0.status == .active }
        if let editingGoal = editingTask?.goal,
           !result.contains(where: { $0.id == editingGoal.id }) {
            result.append(editingGoal)
        }
        return result
    }

    func count(for status: TaskStatus) -> Int {
        tasks.lazy.filter { $0.status == status }.count
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

    func setStatus(_ status: TaskStatus, for task: TaskItem) {
        do {
            try setTaskStatusUseCase.execute(task, status: status)
            load()
        } catch {
            if !(error is TaskStatusTransitionError) {
                AppLogger.error(error, context: "tasks.set_status")
            }
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
