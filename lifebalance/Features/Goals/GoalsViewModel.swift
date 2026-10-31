import Foundation
import Observation

@Observable
@MainActor
final class GoalsViewModel {
    var goals: [Goal] = []
    var lifeAreas: [LifeArea] = []
    var errorMessage: String?
    var showGoalForm = false
    var editingGoal: Goal?
    var selectedStatus: GoalStatus = .active

    private let goalRepository: GoalRepository
    private let lifeAreaRepository: LifeAreaRepository
    private let setGoalStatusUseCase: SetGoalStatusUseCase

    init(
        goalRepository: GoalRepository,
        lifeAreaRepository: LifeAreaRepository,
        setGoalStatusUseCase: SetGoalStatusUseCase
    ) {
        self.goalRepository = goalRepository
        self.lifeAreaRepository = lifeAreaRepository
        self.setGoalStatusUseCase = setGoalStatusUseCase
    }

    var filteredGoals: [Goal] {
        goals.filter { $0.status == selectedStatus }
    }

    func count(for status: GoalStatus) -> Int {
        goals.filter { $0.status == status }.count
    }

    func load() {
        do {
            goals = try goalRepository.fetchAll()
            lifeAreas = try lifeAreaRepository.fetchActiveAreas()
            errorMessage = nil
        } catch {
            AppLogger.error(error, context: "goals.load")
            errorMessage = error.localizedDescription
        }
    }

    func startCreating() {
        editingGoal = nil
        showGoalForm = true
    }

    func startEditing(_ goal: Goal) {
        editingGoal = goal
        showGoalForm = true
    }

    func setStatus(_ status: GoalStatus, for goal: Goal) {
        do {
            try setGoalStatusUseCase.execute(goal, status: status)
            errorMessage = nil
            load()
        } catch {
            if !(error is GoalStatusTransitionError) {
                AppLogger.error(error, context: "goals.set_status")
            }
            errorMessage = error.localizedDescription
        }
    }
}
