import Foundation
import Observation

@Observable
@MainActor
final class GoalFormViewModel {
    var title = ""
    var selectedAreaID: UUID?
    var hasTargetDate = false
    var targetDate = Date.now
    var errorMessage: String?

    let lifeAreas: [LifeArea]
    private let editingGoal: Goal?
    private let createGoalUseCase: CreateGoalUseCase
    private let updateGoalUseCase: UpdateGoalUseCase

    init(
        lifeAreas: [LifeArea],
        editingGoal: Goal?,
        createGoalUseCase: CreateGoalUseCase,
        updateGoalUseCase: UpdateGoalUseCase
    ) {
        self.lifeAreas = lifeAreas
        self.editingGoal = editingGoal
        self.createGoalUseCase = createGoalUseCase
        self.updateGoalUseCase = updateGoalUseCase

        if let editingGoal {
            title = editingGoal.title
            selectedAreaID = editingGoal.lifeArea?.id
            hasTargetDate = editingGoal.targetDate != nil
            targetDate = editingGoal.targetDate ?? .now
        }
    }

    var isEditing: Bool { editingGoal != nil }

    func save() -> Bool {
        do {
            let area = lifeAreas.first { $0.id == selectedAreaID }
            let selectedTargetDate = hasTargetDate ? targetDate : nil
            if let editingGoal {
                try updateGoalUseCase.execute(
                    editingGoal,
                    with: GoalInput(title: title, lifeArea: area, targetDate: selectedTargetDate)
                )
            } else {
                try createGoalUseCase.execute(
                    title: title,
                    lifeArea: area,
                    targetDate: selectedTargetDate
                )
            }
            errorMessage = nil
            return true
        } catch {
            if !(error is GoalValidationError) {
                AppLogger.error(error, context: "goal_form.save")
            }
            errorMessage = error.localizedDescription
            return false
        }
    }
}
