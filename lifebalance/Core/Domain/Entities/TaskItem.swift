import Foundation
import SwiftData

enum TaskStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case active
    case completed
    case archived
}

/// Named `TaskItem` (not `Task`) to avoid clashing with Swift's structured-concurrency `Task`.
extension LifebalanceSchemaV1 {
    @Model
    final class TaskItem: Identifiable {
        var id: UUID
        var title: String
        var note: String?
        var status: TaskStatus
        var dueDate: Date?
        /// `nil` means "not yet triaged" — the PRD's Inbox/"Разобрать" bucket.
        var important: Bool?
        var urgent: Bool?
        var estimateMinutes: Int?
        var createdAt: Date
        var completedAt: Date?
        var lifeArea: LifeArea?
        var goal: Goal?

        init(
            id: UUID = UUID(),
            title: String,
            note: String? = nil,
            status: TaskStatus = .active,
            dueDate: Date? = nil,
            important: Bool? = nil,
            urgent: Bool? = nil,
            estimateMinutes: Int? = nil,
            createdAt: Date = .now,
            completedAt: Date? = nil,
            lifeArea: LifeArea? = nil,
            goal: Goal? = nil
        ) {
            self.id = id
            self.title = title
            self.note = note
            self.status = status
            self.dueDate = dueDate
            self.important = important
            self.urgent = urgent
            self.estimateMinutes = estimateMinutes
            self.createdAt = createdAt
            self.completedAt = completedAt
            self.lifeArea = lifeArea
            self.goal = goal
        }
    }
}

extension LifebalanceSchemaV2 {
    @Model
    final class TaskItem: Identifiable {
        @Attribute(.unique) var id: UUID
        var title: String
        var note: String?
        var status: TaskStatus
        var dueDate: Date?
        /// `nil` means "not yet triaged" — the PRD's Inbox/"Разобрать" bucket.
        var important: Bool?
        var urgent: Bool?
        var estimateMinutes: Int?
        var createdAt: Date
        var completedAt: Date?
        var lifeArea: LifeArea?
        var goal: Goal?

        init(
            id: UUID = UUID(),
            title: String,
            note: String? = nil,
            status: TaskStatus = .active,
            dueDate: Date? = nil,
            important: Bool? = nil,
            urgent: Bool? = nil,
            estimateMinutes: Int? = nil,
            createdAt: Date = .now,
            completedAt: Date? = nil,
            lifeArea: LifeArea? = nil,
            goal: Goal? = nil
        ) {
            self.id = id
            self.title = title
            self.note = note
            self.status = status
            self.dueDate = dueDate
            self.important = important
            self.urgent = urgent
            self.estimateMinutes = estimateMinutes
            self.createdAt = createdAt
            self.completedAt = completedAt
            self.lifeArea = lifeArea
            self.goal = goal
        }
    }
}

extension LifebalanceSchemaV3 {
    @Model
    final class TaskItem: Identifiable {
        @Attribute(.unique) var id: UUID
        var title: String
        var note: String?
        var status: TaskStatus
        var dueDate: Date?
        /// `nil` means "not yet triaged" — the PRD's Inbox/"Разобрать" bucket.
        var important: Bool?
        var urgent: Bool?
        var estimateMinutes: Int?
        var createdAt: Date
        var completedAt: Date?
        var lifeArea: LifebalanceSchemaV2.LifeArea?
        var goal: Goal?

        init(
            id: UUID = UUID(),
            title: String,
            note: String? = nil,
            status: TaskStatus = .active,
            dueDate: Date? = nil,
            important: Bool? = nil,
            urgent: Bool? = nil,
            estimateMinutes: Int? = nil,
            createdAt: Date = .now,
            completedAt: Date? = nil,
            lifeArea: LifebalanceSchemaV2.LifeArea? = nil,
            goal: Goal? = nil
        ) {
            self.id = id
            self.title = title
            self.note = note
            self.status = status
            self.dueDate = dueDate
            self.important = important
            self.urgent = urgent
            self.estimateMinutes = estimateMinutes
            self.createdAt = createdAt
            self.completedAt = completedAt
            self.lifeArea = lifeArea
            self.goal = goal
        }
    }
}

typealias TaskItem = LifebalanceSchemaV3.TaskItem
