import Foundation

enum AnalyticsPeriod: Int, CaseIterable, Hashable, Sendable {
    case sevenDays = 7
    case thirtyDays = 30

    var title: String {
        switch self {
        case .sevenDays: String(localized: "7 дней")
        case .thirtyDays: String(localized: "30 дней")
        }
    }
}

struct AnalyticsDailyPoint: Identifiable, Equatable {
    let date: Date
    let focusMinutes: Int
    let completedTasks: Int

    var id: Date { date }
}

struct AnalyticsAreaFocus: Identifiable, Equatable {
    let id: String
    let name: String
    let colorHex: String
    let minutes: Int
}

struct AnalyticsGoalRow: Identifiable {
    let goal: Goal
    let progress: GoalProgress

    var id: UUID { goal.id }
}

struct AnalyticsBalancePoint: Identifiable, Equatable {
    let date: Date
    let average: Double

    var id: Date { date }
}

struct AnalyticsReport {
    let period: AnalyticsPeriod
    let totalFocusMinutes: Int
    let completedFocusSessions: Int
    let completedTasks: Int
    let createdGoals: Int
    let completedGoals: Int
    let goalCounts: [GoalStatus: Int]
    let daily: [AnalyticsDailyPoint]
    let focusByArea: [AnalyticsAreaFocus]
    let goals: [AnalyticsGoalRow]
    let balanceHistory: [AnalyticsBalancePoint]
}

@MainActor
final class BuildAnalyticsUseCase {
    private let focusSessionRepository: FocusSessionRepository
    private let taskRepository: TaskRepository
    private let goalRepository: GoalRepository
    private let balanceRepository: BalanceRepository

    init(
        focusSessionRepository: FocusSessionRepository,
        taskRepository: TaskRepository,
        goalRepository: GoalRepository,
        balanceRepository: BalanceRepository
    ) {
        self.focusSessionRepository = focusSessionRepository
        self.taskRepository = taskRepository
        self.goalRepository = goalRepository
        self.balanceRepository = balanceRepository
    }

    func execute(
        period: AnalyticsPeriod,
        now: Date = .now,
        calendar: Calendar = .current
    ) throws -> AnalyticsReport {
        let sessions = try focusSessionRepository.fetchAll()
        let tasks = try taskRepository.fetchAll()
        let goals = try goalRepository.fetchAll()
        let goalStatusEvents = try goalRepository.fetchStatusEvents()
        let snapshots = try balanceRepository.fetchAllSnapshots()
        let today = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -(period.rawValue - 1), to: today) ?? today

        let completedSessions = sessions.filter {
            $0.status == .completed && $0.startAt >= start && $0.startAt <= now
        }
        let completedTasks = tasks.filter {
            guard let completedAt = $0.completedAt else { return false }
            return completedAt >= start && completedAt <= now
        }

        var focusByDay: [Date: Int] = [:]
        var tasksByDay: [Date: Int] = [:]
        var areaBuckets: [String: (name: String, colorHex: String, seconds: Int)] = [:]

        for session in completedSessions {
            let seconds = Self.elapsedSeconds(for: session)
            focusByDay[calendar.startOfDay(for: session.startAt), default: 0] += seconds
            let currentArea = session.task?.lifeArea
            let areaID = session.lifeAreaIDSnapshot ?? currentArea?.id
            let key = areaID?.uuidString ?? "unassigned"
            var bucket = areaBuckets[key] ?? (
                name: session.lifeAreaNameSnapshot ?? currentArea?.name ?? String(localized: "Без сферы"),
                colorHex: session.lifeAreaColorHexSnapshot ?? currentArea?.colorHex ?? "8E8E93",
                seconds: 0
            )
            bucket.seconds += seconds
            areaBuckets[key] = bucket
        }

        for task in completedTasks {
            guard let completedAt = task.completedAt else { continue }
            tasksByDay[calendar.startOfDay(for: completedAt), default: 0] += 1
        }

        let daily = (0..<period.rawValue).compactMap { offset -> AnalyticsDailyPoint? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return AnalyticsDailyPoint(
                date: date,
                focusMinutes: focusByDay[date, default: 0] / 60,
                completedTasks: tasksByDay[date, default: 0]
            )
        }

        let balanceHistory = snapshots.compactMap { snapshot -> AnalyticsBalancePoint? in
            guard snapshot.createdAt >= start && snapshot.createdAt <= now else { return nil }
            let values = snapshot.ratings.compactMap(\.value)
            guard !values.isEmpty else { return nil }
            return AnalyticsBalancePoint(
                date: snapshot.createdAt,
                average: Double(values.reduce(0, +)) / Double(values.count)
            )
        }

        return AnalyticsReport(
            period: period,
            totalFocusMinutes: completedSessions.reduce(0) { $0 + Self.elapsedSeconds(for: $1) } / 60,
            completedFocusSessions: completedSessions.count,
            completedTasks: completedTasks.count,
            createdGoals: goals.filter { $0.createdAt >= start && $0.createdAt <= now }.count,
            completedGoals: Set(goalStatusEvents.lazy.filter { event in
                event.status == .completed && event.changedAt >= start && event.changedAt <= now
            }.map(\.goalID)).count,
            goalCounts: Dictionary(grouping: goals, by: \.status).mapValues(\.count),
            daily: daily,
            focusByArea: areaBuckets.map { key, value in
                AnalyticsAreaFocus(
                    id: key,
                    name: value.name,
                    colorHex: value.colorHex,
                    minutes: value.seconds / 60
                )
            }.sorted { $0.minutes > $1.minutes },
            goals: goals
                .filter { $0.status == .active || $0.status == .paused }
                .map { AnalyticsGoalRow(goal: $0, progress: GoalProgressCalculator.summary(for: $0)) },
            balanceHistory: balanceHistory
        )
    }

    private static func elapsedSeconds(for session: FocusSession) -> Int {
        let end = session.endAt ?? session.startAt
        return max(0, Int(end.timeIntervalSince(session.startAt)) - session.pausedSeconds)
    }
}
