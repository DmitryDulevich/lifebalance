import Foundation
import SwiftData

extension LifebalanceSchemaV4 {
    @Model
    final class Habit: Identifiable {
        @Attribute(.unique) var id: UUID
        var title: String
        var targetPerWeek: Int
        var isActive: Bool
        var createdAt: Date
        var lifeArea: LifebalanceSchemaV2.LifeArea?

        @Relationship(deleteRule: .cascade, inverse: \HabitCheckIn.habit)
        var checkIns: [HabitCheckIn] = []

        init(
            id: UUID = UUID(),
            title: String,
            targetPerWeek: Int = 7,
            isActive: Bool = true,
            createdAt: Date = .now,
            lifeArea: LifebalanceSchemaV2.LifeArea? = nil
        ) {
            self.id = id
            self.title = title
            self.targetPerWeek = targetPerWeek
            self.isActive = isActive
            self.createdAt = createdAt
            self.lifeArea = lifeArea
        }
    }

    @Model
    final class HabitCheckIn: Identifiable {
        @Attribute(.unique) var id: UUID
        var completedAt: Date
        var habit: Habit?

        init(id: UUID = UUID(), completedAt: Date = .now, habit: Habit? = nil) {
            self.id = id
            self.completedAt = completedAt
            self.habit = habit
        }
    }
}

typealias Habit = LifebalanceSchemaV4.Habit
typealias HabitCheckIn = LifebalanceSchemaV4.HabitCheckIn
