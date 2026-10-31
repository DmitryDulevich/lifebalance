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

    init(goalRepository: GoalRepository, lifeAreaRepository: LifeAreaRepository) {
        self.goalRepository = goalRepository
        self.lifeAreaRepository = lifeAreaRepository
    }

    func load() {
        do {
            goals = try goalRepository.fetchActive()
            lifeAreas = try lifeAreaRepository.fetchActiveAreas()
            errorMessage = nil
        } catch {
            AppLogger.error(error, context: "goals.load")
            errorMessage = error.localizedDescription
        }
    }
}
