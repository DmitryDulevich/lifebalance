import Foundation
import Observation

@Observable
@MainActor
final class TaskFormViewModel {
    var title: String
    var note: String
    var selectedAreaID: UUID?
    var selectedGoalID: UUID?
    var dueDate: Date?
    var hasDueDate: Bool
    var important: Bool?
    var urgent: Bool?
    var estimateMinutesText: String
    var recurrenceEnabled: Bool
    var recurrenceFrequency: RecurrenceFrequency
    var errorMessage: String?

    let lifeAreas: [LifeArea]
    let goals: [Goal]
    private let editingTask: TaskItem?
    private let createTaskUseCase: CreateTaskUseCase
    private let updateTaskUseCase: UpdateTaskUseCase

    init(
        lifeAreas: [LifeArea],
        goals: [Goal],
        editingTask: TaskItem?,
        preselectedGoal: Goal? = nil,
        createTaskUseCase: CreateTaskUseCase,
        updateTaskUseCase: UpdateTaskUseCase
    ) {
        self.lifeAreas = lifeAreas
        self.goals = goals
        self.editingTask = editingTask
        self.createTaskUseCase = createTaskUseCase
        self.updateTaskUseCase = updateTaskUseCase

        if let task = editingTask {
            title = task.title
            note = task.note ?? ""
            selectedAreaID = task.lifeArea?.id
            selectedGoalID = task.goal?.id
            dueDate = task.dueDate
            hasDueDate = task.dueDate != nil
            important = task.important
            urgent = task.urgent
            estimateMinutesText = task.estimateMinutes.map(String.init) ?? ""
            recurrenceEnabled = false
            recurrenceFrequency = .weekly
        } else {
            title = ""
            note = ""
            selectedAreaID = nil
            selectedGoalID = preselectedGoal?.id
            dueDate = nil
            hasDueDate = false
            important = nil
            urgent = nil
            estimateMinutesText = ""
            recurrenceEnabled = false
            recurrenceFrequency = .weekly
        }
    }

    var isEditing: Bool { editingTask != nil }

    func save() -> Bool {
        let input = TaskInput(
            title: title,
            note: note,
            dueDate: hasDueDate ? (dueDate ?? .now) : nil,
            important: important,
            urgent: urgent,
            estimateMinutes: Int(estimateMinutesText),
            lifeArea: lifeAreas.first { $0.id == selectedAreaID },
            goal: goals.first { $0.id == selectedGoalID },
            recurrence: !isEditing && recurrenceEnabled
                ? TaskRecurrenceInput(frequency: recurrenceFrequency)
                : nil
        )
        do {
            if let editingTask {
                try updateTaskUseCase.execute(editingTask, with: input)
            } else {
                try createTaskUseCase.execute(input)
            }
            errorMessage = nil
            return true
        } catch {
            if !(error is TaskValidationError) {
                AppLogger.error(error, context: "task_form.save")
            }
            errorMessage = error.localizedDescription
            return false
        }
    }
}
