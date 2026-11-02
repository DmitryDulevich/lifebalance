import SwiftUI
import WidgetKit

private struct Snapshot: Codable {
    struct Task: Codable {
        let title: String
        let isOverdue: Bool
    }

    let updatedAt: Date
    let completedCount: Int
    let totalCount: Int
    let focusMinutes: Int
    let tasks: [Task]

    static let empty = Snapshot(
        updatedAt: .now,
        completedCount: 0,
        totalCount: 0,
        focusMinutes: 0,
        tasks: []
    )
}

private enum SnapshotStore {
    static let appGroup = "group.com.dds.lifebalance"
    static let key = "today-widget-snapshot"

    static func load() -> Snapshot {
        guard let data = UserDefaults(suiteName: appGroup)?.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            return .empty
        }
        return snapshot
    }
}

private struct TodayEntry: TimelineEntry {
    let date: Date
    let snapshot: Snapshot
}

private struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: .now, snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(TodayEntry(date: .now, snapshot: SnapshotStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let entry = TodayEntry(date: .now, snapshot: SnapshotStore.load())
        let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

private struct TodayWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TodayEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Сегодня", systemImage: "sun.max.fill")
                    .font(.headline)
                Spacer()
                Text("\(entry.snapshot.completedCount)/\(entry.snapshot.totalCount)")
                    .font(.headline.monospacedDigit())
            }

            if family == .systemSmall {
                Spacer()
                Text("\(entry.snapshot.focusMinutes) мин фокуса")
                    .font(.caption)
                ProgressView(
                    value: Double(entry.snapshot.completedCount),
                    total: Double(max(1, entry.snapshot.totalCount))
                )
                .tint(.indigo)
            } else if entry.snapshot.tasks.isEmpty {
                Spacer()
                Label("План выполнен", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ForEach(Array(entry.snapshot.tasks.prefix(3).enumerated()), id: \.offset) { _, task in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(task.isOverdue ? Color.red : Color.indigo)
                            .frame(width: 6, height: 6)
                        Text(task.title).font(.caption).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                Text("\(entry.snapshot.focusMinutes) мин фокуса")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

struct TodayWidget: Widget {
    let kind = "TodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
            TodayWidgetView(entry: entry)
        }
        .configurationDisplayName("Сегодня")
        .description("Задачи и прогресс текущего дня.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct TodayWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayWidget()
    }
}
