import Foundation
import Observation

@Observable
@MainActor
final class GoalsViewModel {
    var goals: [Goal] = []
    var lifeAreas: [LifeArea] = []
    var errorMessage: String?
    var showGoalForm = false

    private let goalRepository: GoalRepository
    private let lifeAreaRepository: LifeAreaRepository

    init(container: AppContainer) {
        self.goalRepository = container.goalRepository
        self.lifeAreaRepository = container.lifeAreaRepository
    }

    func load() {
        do {
            goals = try goalRepository.fetchActive()
            lifeAreas = try lifeAreaRepository.fetchActiveAreas()
        } catch {
            AppLogger.error(error, context: "goals.load")
            errorMessage = error.localizedDescription
        }
    }
}
