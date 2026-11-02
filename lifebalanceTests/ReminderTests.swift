import Foundation
import Testing
@testable import lifebalance

@Suite("Reminders")
@MainActor
struct ReminderTests {
    @Test("Reminder preferences survive a store round trip")
    func preferencesRoundTrip() throws {
        let suiteName = "ReminderTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = ReminderPreferencesStore(defaults: defaults)
        let expected = ReminderPreferences(
            taskRemindersEnabled: true,
            taskLeadMinutes: 15,
            habitRemindersEnabled: true,
            habitReminderMinutes: 8 * 60,
            weeklyReviewEnabled: true,
            weeklyReviewWeekday: 2,
            weeklyReviewMinutes: 19 * 60
        )

        try store.save(expected)

        #expect(store.load() == expected)
    }

    @Test("Refresh sends tasks, active-habit state and preferences to scheduler")
    func refreshUsesCurrentData() async throws {
        let taskRepository = FakeTaskRepository()
        let task = TaskItem(title: "Private title", dueDate: .now.addingTimeInterval(3_600))
        taskRepository.tasks = [task]
        let habitRepository = FakeReminderHabitRepository(habits: [Habit(title: "Walk")])
        let suiteName = "ReminderTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = ReminderPreferencesStore(defaults: defaults)
        var preferences = ReminderPreferences()
        preferences.taskRemindersEnabled = true
        try store.save(preferences)
        let scheduler = FakeReminderScheduler()
        let useCase = RefreshRemindersUseCase(
            taskRepository: taskRepository,
            habitRepository: habitRepository,
            preferencesStore: store,
            scheduler: scheduler
        )
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        try await useCase.execute(now: now)

        #expect(scheduler.lastTasks.map(\.id) == [task.id])
        #expect(scheduler.lastHasActiveHabits == true)
        #expect(scheduler.lastPreferences == preferences)
        #expect(scheduler.lastNow == now)
    }
}

@MainActor
private final class FakeReminderHabitRepository: HabitRepository {
    var habits: [Habit]

    init(habits: [Habit]) {
        self.habits = habits
    }

    func fetchAll() throws -> [Habit] { habits }
    func insert(_ habit: Habit) throws { habits.append(habit) }
    func delete(_ habit: Habit) throws { habits.removeAll { $0.id == habit.id } }
    func toggleCheckIn(for habit: Habit, on date: Date, calendar: Calendar) throws {}
    func save() throws {}
}

@MainActor
private final class FakeReminderScheduler: ReminderScheduling {
    private(set) var lastTasks: [TaskItem] = []
    private(set) var lastHasActiveHabits = false
    private(set) var lastPreferences = ReminderPreferences()
    private(set) var lastNow: Date?

    func requestAuthorization() async throws -> Bool { true }
    func authorizationState() async -> ReminderAuthorizationState { .authorized }

    func refresh(
        tasks: [TaskItem],
        hasActiveHabits: Bool,
        preferences: ReminderPreferences,
        now: Date
    ) async throws {
        lastTasks = tasks
        lastHasActiveHabits = hasActiveHabits
        lastPreferences = preferences
        lastNow = now
    }
}
