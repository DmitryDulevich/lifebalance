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

typealias FocusSession = LifebalanceSchemaV1.FocusSession
