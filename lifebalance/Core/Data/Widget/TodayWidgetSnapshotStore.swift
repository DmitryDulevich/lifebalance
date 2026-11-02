import Foundation
import WidgetKit

struct TodayWidgetSnapshot: Codable {
    struct Task: Codable {
        let title: String
        let isOverdue: Bool
    }

    let updatedAt: Date
    let completedCount: Int
    let totalCount: Int
    let focusMinutes: Int
    let tasks: [Task]
}

enum TodayWidgetSnapshotStore {
    static let appGroup = "group.com.dds.lifebalance"
    private static let key = "today-widget-snapshot"

    static func save(_ snapshot: TodayWidgetSnapshot) {
        guard let defaults = UserDefaults(suiteName: appGroup),
              let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
        WidgetCenter.shared.reloadTimelines(ofKind: "TodayWidget")
    }
}
