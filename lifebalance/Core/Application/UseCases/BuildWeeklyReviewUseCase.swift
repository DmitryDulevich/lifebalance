import Foundation

struct WeeklyReviewReport {
    let weekStart: Date
    let weekEnd: Date
    let completedTasks: [TaskItem]
    let unfinishedTasks: [TaskItem]
    let focusMinutes: Int
    let habitCheckInCount: Int
    let habitTargetCount: Int
    let balanceAverage: Double?
}

@MainActor
final class BuildWeeklyReviewUseCase {
    private let taskRepository: TaskRepository
    private let focusSessionRepository: FocusSessionRepository
    private let balanceRepository: BalanceRepository
    private let habitRepository: HabitRepository

    init(
        taskRepository: TaskRepository,
        focusSessionRepository: FocusSessionRepository,
        balanceRepository: BalanceRepository,
        habitRepository: HabitRepository
    ) {
        self.taskRepository = taskRepository
        self.focusSessionRepository = focusSessionRepository
        self.balanceRepository = balanceRepository
        self.habitRepository = habitRepository
    }

    func execute(now: Date = .now, calendar: Calendar = .current) throws -> WeeklyReviewReport {
        var calendar = calendar
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        let interval = calendar.dateInterval(of: .weekOfYear, for: now)
            ?? DateInterval(start: calendar.startOfDay(for: now), duration: 7 * 86_400)

        let tasks = try taskRepository.fetchAll()
        let completed = tasks.filter {
            $0.status == .completed && interval.contains($0.completedAt ?? .distantPast)
        }
        let unfinished = tasks.filter {
            $0.status == .active && ($0.dueDate ?? .distantFuture) < interval.end
        }
        let focusSeconds = try focusSessionRepository.fetchAll()
            .filter { $0.status == .completed && interval.contains($0.startAt) }
            .reduce(0) { result, session in
                let end = session.endAt ?? session.startAt
                return result + max(0, Int(end.timeIntervalSince(session.startAt)) - session.pausedSeconds)
            }
        let habits = try habitRepository.fetchAll().filter(\.isActive)
        let checkIns = habits.flatMap(\.checkIns).filter { interval.contains($0.completedAt) }.count
        let ratings = try balanceRepository.fetchAllSnapshots()
            .filter { interval.contains($0.createdAt) }
            .flatMap(\.ratings)
            .compactMap(\.value)
        let balanceAverage = ratings.isEmpty
            ? nil
            : Double(ratings.reduce(0, +)) / Double(ratings.count)

        return WeeklyReviewReport(
            weekStart: interval.start,
            weekEnd: interval.end,
            completedTasks: completed,
            unfinishedTasks: unfinished,
            focusMinutes: focusSeconds / 60,
            habitCheckInCount: checkIns,
            habitTargetCount: habits.reduce(0) { $0 + $1.targetPerWeek },
            balanceAverage: balanceAverage
        )
    }
}
