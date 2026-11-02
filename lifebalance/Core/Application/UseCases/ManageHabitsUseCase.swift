import Foundation

enum HabitValidationError: LocalizedError {
    case emptyTitle
    case invalidWeeklyTarget

    var errorDescription: String? {
        switch self {
        case .emptyTitle: String(localized: "Введите название привычки.")
        case .invalidWeeklyTarget: String(localized: "Цель должна быть от 1 до 7 раз в неделю.")
        }
    }
}

@MainActor
final class ManageHabitsUseCase {
    private let repository: HabitRepository

    init(repository: HabitRepository) {
        self.repository = repository
    }

    func create(title: String, targetPerWeek: Int, lifeArea: LifeArea?) throws {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw HabitValidationError.emptyTitle }
        guard (1...7).contains(targetPerWeek) else { throw HabitValidationError.invalidWeeklyTarget }
        try repository.insert(Habit(title: title, targetPerWeek: targetPerWeek, lifeArea: lifeArea))
    }

    func toggleToday(_ habit: Habit, now: Date = .now, calendar: Calendar = .current) throws {
        try repository.toggleCheckIn(for: habit, on: now, calendar: calendar)
    }

    func setActive(_ isActive: Bool, for habit: Habit) throws {
        let previous = habit.isActive
        habit.isActive = isActive
        do { try repository.save() } catch {
            habit.isActive = previous
            throw error
        }
    }
}
