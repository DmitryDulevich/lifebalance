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

typealias Goal = LifebalanceSchemaV2.Goal
