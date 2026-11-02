import Foundation
import SwiftData

@MainActor
final class SwiftDataHabitRepository: HabitRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdAt)])
        return try context.fetch(descriptor)
    }

    func insert(_ habit: Habit) throws {
        context.insert(habit)
        try context.save()
    }

    func delete(_ habit: Habit) throws {
        context.delete(habit)
        try context.save()
    }

    func toggleCheckIn(for habit: Habit, on date: Date, calendar: Calendar = .current) throws {
        if let checkIn = habit.checkIns.first(where: { calendar.isDate($0.completedAt, inSameDayAs: date) }) {
            context.delete(checkIn)
        } else {
            context.insert(HabitCheckIn(completedAt: date, habit: habit))
        }
        try context.save()
    }

    func save() throws {
        try context.save()
    }
}
