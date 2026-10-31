import Foundation
import Observation

struct AreaRatingDraft: Identifiable {
    let area: LifeArea
    var value: Int?
    var note: String = ""

    var id: UUID { area.id }
}

@Observable
@MainActor
final class InitialBalanceViewModel {
    var drafts: [AreaRatingDraft] = []
    var errorMessage: String?

    private let lifeAreaRepository: LifeAreaRepository
    private let saveBalanceSnapshotUseCase: SaveBalanceSnapshotUseCase
    private let advanceOnboardingStepUseCase: AdvanceOnboardingStepUseCase

    init(
        lifeAreaRepository: LifeAreaRepository,
        saveBalanceSnapshotUseCase: SaveBalanceSnapshotUseCase,
        advanceOnboardingStepUseCase: AdvanceOnboardingStepUseCase
    ) {
        self.lifeAreaRepository = lifeAreaRepository
        self.saveBalanceSnapshotUseCase = saveBalanceSnapshotUseCase
        self.advanceOnboardingStepUseCase = advanceOnboardingStepUseCase
    }

    var canSave: Bool {
        drafts.contains { $0.value != nil }
    }

    func loadAreas() {
        do {
            let areas = try lifeAreaRepository.fetchActiveAreas()
            drafts = areas.map { AreaRatingDraft(area: $0) }
            errorMessage = nil
        } catch {
            AppLogger.error(error, context: "onboarding.initial_balance.load")
            errorMessage = error.localizedDescription
        }
    }

    func binding(for id: UUID) -> Int? {
        drafts.first { $0.id == id }?.value
    }

    func setValue(_ value: Int?, for id: UUID) {
        guard let index = drafts.firstIndex(where: { $0.id == id }) else { return }
        drafts[index].value = value
    }

    func setNote(_ note: String, for id: UUID) {
        guard let index = drafts.firstIndex(where: { $0.id == id }) else { return }
        drafts[index].note = note
    }

    func save() -> Bool {
        let ratings = drafts.map {
            AreaRatingInput(
                area: $0.area,
                value: $0.value,
                note: $0.note.isEmpty ? nil : $0.note
            )
        }
        do {
            try saveBalanceSnapshotUseCase.execute(ratings: ratings, note: nil)
            errorMessage = nil
            return true
        } catch {
            if !(error is SaveBalanceSnapshotUseCase.ValidationError) {
                AppLogger.error(error, context: "onboarding.initial_balance.save")
            }
            errorMessage = error.localizedDescription
            return false
        }
    }

    func skip() -> Bool {
        do {
            try advanceOnboardingStepUseCase.execute(to: .completed)
            errorMessage = nil
            return true
        } catch {
            AppLogger.error(error, context: "onboarding.initial_balance.skip")
            errorMessage = error.localizedDescription
            return false
        }
    }
}
