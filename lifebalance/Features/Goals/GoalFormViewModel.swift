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
    private let createGoalUseCase: CreateGoalUseCase

    init(container: AppContainer, lifeAreas: [LifeArea]) {
        self.lifeAreas = lifeAreas
        self.createGoalUseCase = container.createGoalUseCase
    }

    func save() -> Bool {
        do {
            try createGoalUseCase.execute(
                title: title,
                lifeArea: lifeAreas.first { $0.id == selectedAreaID },
                targetDate: hasTargetDate ? targetDate : nil
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
