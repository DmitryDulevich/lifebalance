import Foundation
import Observation

@Observable
@MainActor
final class HabitsViewModel {
    struct HabitProgress: Identifiable {
        let habit: Habit
        let completedThisWeek: Int
        let isDoneToday: Bool
        let currentStreak: Int

        var id: UUID { habit.id }
        var fraction: Double {
            min(1, Double(completedThisWeek) / Double(max(1, habit.targetPerWeek)))
        }
    }

    var habits: [HabitProgress] = []
    var lifeAreas: [LifeArea] = []
    var errorMessage: String?

    let recurringTaskRepository: RecurringTaskRepository

    private let habitRepository: HabitRepository
    private let lifeAreaRepository: LifeAreaRepository
    private let manageHabitsUseCase: ManageHabitsUseCase
    private let refreshRemindersUseCase: RefreshRemindersUseCase?

    init(
        habitRepository: HabitRepository,
        lifeAreaRepository: LifeAreaRepository,
        manageHabitsUseCase: ManageHabitsUseCase,
        recurringTaskRepository: RecurringTaskRepository,
        refreshRemindersUseCase: RefreshRemindersUseCase? = nil
    ) {
        self.habitRepository = habitRepository
        self.lifeAreaRepository = lifeAreaRepository
        self.manageHabitsUseCase = manageHabitsUseCase
        self.recurringTaskRepository = recurringTaskRepository
        self.refreshRemindersUseCase = refreshRemindersUseCase
    }

    func load(now: Date = .now, calendar: Calendar = .current) {
        do {
            var calendar = calendar
            calendar.firstWeekday = 2
            let week = calendar.dateInterval(of: .weekOfYear, for: now)
            habits = try habitRepository.fetchAll().map { habit in
                HabitProgress(
                    habit: habit,
                    completedThisWeek: habit.checkIns.filter {
                        week?.contains($0.completedAt) == true
                    }.count,
                    isDoneToday: habit.checkIns.contains {
                        calendar.isDate($0.completedAt, inSameDayAs: now)
                    },
                    currentStreak: Self.streak(for: habit, now: now, calendar: calendar)
                )
            }
            lifeAreas = try lifeAreaRepository.fetchActiveAreas()
            Task { try? await refreshRemindersUseCase?.execute() }
            errorMessage = nil
        } catch {
            AppLogger.error(error, context: "habits.load")
            errorMessage = error.localizedDescription
        }
    }

    private static func streak(for habit: Habit, now: Date, calendar: Calendar) -> Int {
        let completedDays = Set(habit.checkIns.map { calendar.startOfDay(for: $0.completedAt) })
        var day = calendar.startOfDay(for: now)
        if !completedDays.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        var result = 0
        while completedDays.contains(day) {
            result += 1
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return result
    }

    func create(title: String, targetPerWeek: Int, areaID: UUID?) -> Bool {
        do {
            try manageHabitsUseCase.create(
                title: title,
                targetPerWeek: targetPerWeek,
                lifeArea: lifeAreas.first { $0.id == areaID }
            )
            load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func toggleToday(_ habit: Habit) {
        do {
            try manageHabitsUseCase.toggleToday(habit)
            load()
        } catch {
            AppLogger.error(error, context: "habits.toggle")
            errorMessage = error.localizedDescription
        }
    }

    func toggleActive(_ habit: Habit) {
        do {
            try manageHabitsUseCase.setActive(!habit.isActive, for: habit)
            load()
        } catch {
            AppLogger.error(error, context: "habits.status")
            errorMessage = error.localizedDescription
        }
    }
}
