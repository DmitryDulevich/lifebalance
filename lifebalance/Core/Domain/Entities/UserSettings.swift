import Foundation
import SwiftData

enum OnboardingStep: String, Codable, CaseIterable, Sendable {
    case welcome
    case areaSelection
    case initialBalance
    case completed
}

extension LifebalanceSchemaV1 {
    @Model
    final class UserSettings {
        var id: UUID
        var onboardingStep: OnboardingStep
        var createdAt: Date

        init(
            id: UUID = UUID(),
            onboardingStep: OnboardingStep = .welcome,
            createdAt: Date = .now
        ) {
            self.id = id
            self.onboardingStep = onboardingStep
            self.createdAt = createdAt
        }
    }
}

typealias UserSettings = LifebalanceSchemaV1.UserSettings
