import Foundation
import SwiftData

enum FocusSessionStatus: String, Codable, Sendable {
    case running
    case paused
    case completed
    case cancelled
}

@Model
final class FocusSession {
    var id: UUID
    var startAt: Date
    var endAt: Date?
    var plannedSeconds: Int
    var pausedSeconds: Int
    var status: FocusSessionStatus
    var task: TaskItem?

    init(
        id: UUID = UUID(),
        startAt: Date = .now,
        endAt: Date? = nil,
        plannedSeconds: Int,
        pausedSeconds: Int = 0,
        status: FocusSessionStatus = .running,
        task: TaskItem? = nil
    ) {
        self.id = id
        self.startAt = startAt
        self.endAt = endAt
        self.plannedSeconds = plannedSeconds
        self.pausedSeconds = pausedSeconds
        self.status = status
        self.task = task
    }
}
