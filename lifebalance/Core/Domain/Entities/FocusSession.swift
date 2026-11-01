import Foundation
import SwiftData

enum FocusSessionStatus: String, Codable, Sendable {
    case running
    case paused
    case completed
    case cancelled
}

extension LifebalanceSchemaV1 {
    @Model
    final class FocusSession: Identifiable {
        var id: UUID
        var startAt: Date
        var endAt: Date?
        var plannedSeconds: Int
        var pausedSeconds: Int
        var pausedAt: Date?
        var status: FocusSessionStatus
        var task: TaskItem?

        init(
            id: UUID = UUID(),
            startAt: Date = .now,
            endAt: Date? = nil,
            plannedSeconds: Int,
            pausedSeconds: Int = 0,
            pausedAt: Date? = nil,
            status: FocusSessionStatus = .running,
            task: TaskItem? = nil
        ) {
            self.id = id
            self.startAt = startAt
            self.endAt = endAt
            self.plannedSeconds = plannedSeconds
            self.pausedSeconds = pausedSeconds
            self.pausedAt = pausedAt
            self.status = status
            self.task = task
        }
    }
}

extension LifebalanceSchemaV2 {
    @Model
    final class FocusSession: Identifiable {
        @Attribute(.unique) var id: UUID
        var startAt: Date
        var endAt: Date?
        var plannedSeconds: Int
        var pausedSeconds: Int
        var pausedAt: Date?
        var status: FocusSessionStatus
        var task: TaskItem?

        init(
            id: UUID = UUID(),
            startAt: Date = .now,
            endAt: Date? = nil,
            plannedSeconds: Int,
            pausedSeconds: Int = 0,
            pausedAt: Date? = nil,
            status: FocusSessionStatus = .running,
            task: TaskItem? = nil
        ) {
            self.id = id
            self.startAt = startAt
            self.endAt = endAt
            self.plannedSeconds = plannedSeconds
            self.pausedSeconds = pausedSeconds
            self.pausedAt = pausedAt
            self.status = status
            self.task = task
        }
    }
}

extension LifebalanceSchemaV3 {
    @Model
    final class FocusSession: Identifiable {
        @Attribute(.unique) var id: UUID
        var startAt: Date
        var endAt: Date?
        var plannedSeconds: Int
        var pausedSeconds: Int
        var pausedAt: Date?
        var status: FocusSessionStatus
        var task: TaskItem?

        /// Immutable labels used by historical analytics even after related models change.
        var taskIDSnapshot: UUID?
        var taskTitleSnapshot: String?
        var lifeAreaIDSnapshot: UUID?
        var lifeAreaNameSnapshot: String?
        var lifeAreaColorHexSnapshot: String?
        var goalIDSnapshot: UUID?
        var goalTitleSnapshot: String?

        init(
            id: UUID = UUID(),
            startAt: Date = .now,
            endAt: Date? = nil,
            plannedSeconds: Int,
            pausedSeconds: Int = 0,
            pausedAt: Date? = nil,
            status: FocusSessionStatus = .running,
            task: TaskItem? = nil,
            taskIDSnapshot: UUID? = nil,
            taskTitleSnapshot: String? = nil,
            lifeAreaIDSnapshot: UUID? = nil,
            lifeAreaNameSnapshot: String? = nil,
            lifeAreaColorHexSnapshot: String? = nil,
            goalIDSnapshot: UUID? = nil,
            goalTitleSnapshot: String? = nil
        ) {
            self.id = id
            self.startAt = startAt
            self.endAt = endAt
            self.plannedSeconds = plannedSeconds
            self.pausedSeconds = pausedSeconds
            self.pausedAt = pausedAt
            self.status = status
            self.task = task
            self.taskIDSnapshot = taskIDSnapshot ?? task?.id
            self.taskTitleSnapshot = taskTitleSnapshot ?? task?.title
            self.lifeAreaIDSnapshot = lifeAreaIDSnapshot ?? task?.lifeArea?.id
            self.lifeAreaNameSnapshot = lifeAreaNameSnapshot ?? task?.lifeArea?.name
            self.lifeAreaColorHexSnapshot = lifeAreaColorHexSnapshot ?? task?.lifeArea?.colorHex
            self.goalIDSnapshot = goalIDSnapshot ?? task?.goal?.id
            self.goalTitleSnapshot = goalTitleSnapshot ?? task?.goal?.title
        }
    }
}

typealias FocusSession = LifebalanceSchemaV3.FocusSession
