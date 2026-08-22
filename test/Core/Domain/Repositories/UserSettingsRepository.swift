import Foundation

@MainActor
protocol UserSettingsRepository {
    func fetchOrCreate() throws -> UserSettings
    func updateOnboardingStep(_ step: OnboardingStep) throws
}
