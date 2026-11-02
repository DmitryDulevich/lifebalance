import Foundation
import SwiftData

enum RecurrenceFrequency: String, Codable, CaseIterable, Hashable, Sendable {
    case daily
    case weekdays
    case weekly
    case monthly

    var localizedTitle: String {
        switch self {
        case .daily: String(localized: "Каждый день")
        case .weekdays: String(localized: "По рабочим дням")
        case .weekly: String(localized: "Каждую неделю")
        case .monthly: String(localized: "Каждый месяц")
        }
    }
}

struct TaskRecurrenceInput: Equatable, Sendable {
    var frequency: RecurrenceFrequency
    var interval: Int = 1
}

extension LifebalanceSchemaV4 {
    @Model
    final class RecurringTask: Identifiable {
        @Attribute(.unique) var id: UUID
        var sourceTaskID: UUID
        var title: String
        var taskNote: String?
        var frequency: RecurrenceFrequency
        var recurrenceInterval: Int
        var nextDueDate: Date
        var isActive: Bool
        var important: Bool?
        var urgent: Bool?
        var estimateMinutes: Int?
        var createdAt: Date
        var lifeArea: LifebalanceSchemaV2.LifeArea?
        var goal: LifebalanceSchemaV2.Goal?

        init(
            id: UUID = UUID(),
            sourceTaskID: UUID,
            title: String,
            taskNote: String? = nil,
            frequency: RecurrenceFrequency,
            recurrenceInterval: Int = 1,
            nextDueDate: Date,
            isActive: Bool = true,
            important: Bool? = nil,
            urgent: Bool? = nil,
            estimateMinutes: Int? = nil,
            createdAt: Date = .now,
            lifeArea: LifebalanceSchemaV2.LifeArea? = nil,
            goal: LifebalanceSchemaV2.Goal? = nil
        ) {
            self.id = id
            self.sourceTaskID = sourceTaskID
            self.title = title
            self.taskNote = taskNote
            self.frequency = frequency
            self.recurrenceInterval = recurrenceInterval
            self.nextDueDate = nextDueDate
            self.isActive = isActive
            self.important = important
            self.urgent = urgent
            self.estimateMinutes = estimateMinutes
            self.createdAt = createdAt
            self.lifeArea = lifeArea
            self.goal = goal
        }
    }
}

typealias RecurringTask = LifebalanceSchemaV4.RecurringTask

enum RecurrenceCalculator {
    static func nextDate(
        after date: Date,
        frequency: RecurrenceFrequency,
        interval: Int = 1,
        calendar: Calendar = .current
    ) -> Date {
        let interval = max(1, interval)
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: interval, to: date) ?? date
        case .weekdays:
            var candidate = date
            var remaining = interval
            while remaining > 0 {
                candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
                if !calendar.isDateInWeekend(candidate) {
                    remaining -= 1
                }
            }
            return candidate
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: interval, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: interval, to: date) ?? date
        }
    }
}
