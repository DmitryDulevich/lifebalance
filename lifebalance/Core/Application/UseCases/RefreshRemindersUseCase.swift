import Foundation

@MainActor
final class RefreshRemindersUseCase {
    private let taskRepository: TaskRepository
    private let habitRepository: HabitRepository
    private let preferencesStore: ReminderPreferencesStore
    private let scheduler: ReminderScheduling

    init(
        taskRepository: TaskRepository,
        habitRepository: HabitRepository,
        preferencesStore: ReminderPreferencesStore,
        scheduler: ReminderScheduling
    ) {
        self.taskRepository = taskRepository
        self.habitRepository = habitRepository
        self.preferencesStore = preferencesStore
        self.scheduler = scheduler
    }

    func execute(now: Date = .now) async throws {
        try await scheduler.refresh(
            tasks: taskRepository.fetchAll(),
            hasActiveHabits: habitRepository.fetchAll().contains(where: \.isActive),
            preferences: preferencesStore.load(),
            now: now
        )
    }
}
