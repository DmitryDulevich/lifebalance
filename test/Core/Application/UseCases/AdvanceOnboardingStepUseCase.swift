import Foundation

@MainActor
final class AdvanceOnboardingStepUseCase {
    private let userSettingsRepository: UserSettingsRepository

    init(userSettingsRepository: UserSettingsRepository) {
        self.userSettingsRepository = userSettingsRepository
    }

    func execute(to step: OnboardingStep) throws {
        try userSettingsRepository.updateOnboardingStep(step)
    }
}
