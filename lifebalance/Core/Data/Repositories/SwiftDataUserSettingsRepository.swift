import Foundation
import SwiftData

@MainActor
final class SwiftDataUserSettingsRepository: UserSettingsRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchOrCreate() throws -> UserSettings {
        var descriptor = FetchDescriptor<UserSettings>()
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            return existing
        }
        let settings = UserSettings()
        context.insert(settings)
        try context.save()
        return settings
    }

    func updateOnboardingStep(_ step: OnboardingStep) throws {
        let settings = try fetchOrCreate()
        settings.onboardingStep = step
        try context.save()
    }
}
