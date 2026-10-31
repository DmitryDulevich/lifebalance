import Foundation
import Observation

@Observable
@MainActor
final class WelcomeViewModel {
    var errorMessage: String?
    var showPrivacyPolicy = false

    private let advanceOnboardingStepUseCase: AdvanceOnboardingStepUseCase

    init(advanceOnboardingStepUseCase: AdvanceOnboardingStepUseCase) {
        self.advanceOnboardingStepUseCase = advanceOnboardingStepUseCase
    }

    func start() -> Bool {
        do {
            try advanceOnboardingStepUseCase.execute(to: .areaSelection)
            errorMessage = nil
            return true
        } catch {
            AppLogger.error(error, context: "onboarding.welcome.start")
            errorMessage = error.localizedDescription
            return false
        }
    }
}
