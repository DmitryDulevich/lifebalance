import Foundation
import SwiftData

extension LifebalanceSchemaV4 {
    @Model
    final class WeeklyReview: Identifiable {
        @Attribute(.unique) var id: UUID
        @Attribute(.unique) var weekStart: Date
        var completedAt: Date
        var completedTaskCount: Int
        var focusMinutes: Int
        var habitCheckInCount: Int
        var balanceAverage: Double?
        var note: String?
        var priorities: String?

        init(
            id: UUID = UUID(),
            weekStart: Date,
            completedAt: Date = .now,
            completedTaskCount: Int,
            focusMinutes: Int,
            habitCheckInCount: Int,
            balanceAverage: Double? = nil,
            note: String? = nil,
            priorities: String? = nil
        ) {
            self.id = id
            self.weekStart = weekStart
            self.completedAt = completedAt
            self.completedTaskCount = completedTaskCount
            self.focusMinutes = focusMinutes
            self.habitCheckInCount = habitCheckInCount
            self.balanceAverage = balanceAverage
            self.note = note
            self.priorities = priorities
        }
    }
}

typealias WeeklyReview = LifebalanceSchemaV4.WeeklyReview
