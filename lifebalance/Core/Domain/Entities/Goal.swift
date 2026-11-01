import Foundation
import SwiftData

enum GoalStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case active
    case completed
    case paused
    case archived
}

extension LifebalanceSchemaV1 {
    @Model
    final class Goal: Identifiable {
        var id: UUID
        var title: String
        var status: GoalStatus
        var targetDate: Date?
        var createdAt: Date
        var lifeArea: LifeArea?

        @Relationship(deleteRule: .nullify, inverse: \TaskItem.goal)
        var tasks: [TaskItem] = []

        init(
            id: UUID = UUID(),
            title: String,
            status: GoalStatus = .active,
            targetDate: Date? = nil,
            createdAt: Date = .now,
            lifeArea: LifeArea? = nil
        ) {
            self.id = id
            self.title = title
            self.status = status
            self.targetDate = targetDate
            self.createdAt = createdAt
            self.lifeArea = lifeArea
        }
    }
}

extension LifebalanceSchemaV2 {
    @Model
    final class Goal: Identifiable {
        @Attribute(.unique) var id: UUID
        var title: String
        var status: GoalStatus
        var targetDate: Date?
        var createdAt: Date
        var lifeArea: LifeArea?

        @Relationship(deleteRule: .nullify, inverse: \TaskItem.goal)
        var tasks: [TaskItem] = []

        init(
            id: UUID = UUID(),
            title: String,
            status: GoalStatus = .active,
            targetDate: Date? = nil,
            createdAt: Date = .now,
            lifeArea: LifeArea? = nil
        ) {
            self.id = id
            self.title = title
            self.status = status
            self.targetDate = targetDate
            self.createdAt = createdAt
            self.lifeArea = lifeArea
        }
    }
}

extension LifebalanceSchemaV3 {
    @Model
    final class Goal: Identifiable {
        @Attribute(.unique) var id: UUID
        var title: String
        var status: GoalStatus
        var targetDate: Date?
        var createdAt: Date
        var lifeArea: LifebalanceSchemaV2.LifeArea?

        @Relationship(deleteRule: .nullify, inverse: \TaskItem.goal)
        var tasks: [TaskItem] = []

        init(
            id: UUID = UUID(),
            title: String,
            status: GoalStatus = .active,
            targetDate: Date? = nil,
            createdAt: Date = .now,
            lifeArea: LifebalanceSchemaV2.LifeArea? = nil
        ) {
            self.id = id
            self.title = title
            self.status = status
            self.targetDate = targetDate
            self.createdAt = createdAt
            self.lifeArea = lifeArea
        }
    }

    @Model
    final class GoalStatusEvent: Identifiable {
        @Attribute(.unique) var id: UUID
        var goalID: UUID
        var goalTitleSnapshot: String
        var status: GoalStatus
        var changedAt: Date

        init(
            id: UUID = UUID(),
            goalID: UUID,
            goalTitleSnapshot: String,
            status: GoalStatus,
            changedAt: Date = .now
        ) {
            self.id = id
            self.goalID = goalID
            self.goalTitleSnapshot = goalTitleSnapshot
            self.status = status
            self.changedAt = changedAt
        }
    }
}

typealias Goal = LifebalanceSchemaV3.Goal
typealias GoalStatusEvent = LifebalanceSchemaV3.GoalStatusEvent
