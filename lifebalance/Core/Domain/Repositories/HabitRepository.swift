import Foundation

@MainActor
protocol HabitRepository {
    func fetchAll() throws -> [Habit]
    func insert(_ habit: Habit) throws
    func delete(_ habit: Habit) throws
    func toggleCheckIn(for habit: Habit, on date: Date, calendar: Calendar) throws
    func save() throws
}
