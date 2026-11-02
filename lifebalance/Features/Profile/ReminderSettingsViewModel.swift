import Foundation
import Observation

@Observable
@MainActor
final class ReminderSettingsViewModel {
    var preferences = ReminderPreferences()
    var authorizationState: ReminderAuthorizationState = .notDetermined
    var errorMessage: String?

    private let preferencesStore: ReminderPreferencesStore
    private let scheduler: ReminderScheduling
    private let refreshRemindersUseCase: RefreshRemindersUseCase

    init(
        preferencesStore: ReminderPreferencesStore,
        scheduler: ReminderScheduling,
        refreshRemindersUseCase: RefreshRemindersUseCase
    ) {
        self.preferencesStore = preferencesStore
        self.scheduler = scheduler
        self.refreshRemindersUseCase = refreshRemindersUseCase
    }

    func load() async {
        preferences = preferencesStore.load()
        authorizationState = await scheduler.authorizationState()
    }

    func setTaskRemindersEnabled(_ enabled: Bool) async {
        await update(enabled: enabled) { $0.taskRemindersEnabled = $1 }
    }

    func setHabitRemindersEnabled(_ enabled: Bool) async {
        await update(enabled: enabled) { $0.habitRemindersEnabled = $1 }
    }

    func setWeeklyReviewEnabled(_ enabled: Bool) async {
        await update(enabled: enabled) { $0.weeklyReviewEnabled = $1 }
    }

    func save() {
        Task { await persistAndRefresh() }
    }

    var habitReminderDate: Date {
        get { Self.date(minutes: preferences.habitReminderMinutes) }
        set {
            preferences.habitReminderMinutes = Self.minutes(date: newValue)
            save()
        }
    }

    var weeklyReviewDate: Date {
        get { Self.date(minutes: preferences.weeklyReviewMinutes) }
        set {
            preferences.weeklyReviewMinutes = Self.minutes(date: newValue)
            save()
        }
    }

    private func update(
        enabled: Bool,
        mutation: (inout ReminderPreferences, Bool) -> Void
    ) async {
        if enabled && authorizationState != .authorized {
            do {
                let granted = try await scheduler.requestAuthorization()
                authorizationState = await scheduler.authorizationState()
                guard granted else {
                    errorMessage = String(localized: "Разрешите уведомления в настройках iOS.")
                    return
                }
            } catch {
                AppLogger.error(error, context: "reminders.authorization")
                errorMessage = error.localizedDescription
                return
            }
        }
        mutation(&preferences, enabled)
        await persistAndRefresh()
    }

    private func persistAndRefresh() async {
        do {
            try preferencesStore.save(preferences)
            try await refreshRemindersUseCase.execute()
            authorizationState = await scheduler.authorizationState()
            errorMessage = nil
        } catch {
            AppLogger.error(error, context: "reminders.save")
            errorMessage = error.localizedDescription
        }
    }

    private static func date(minutes: Int) -> Date {
        Calendar.current.date(
            bySettingHour: minutes / 60,
            minute: minutes % 60,
            second: 0,
            of: .now
        ) ?? .now
    }

    private static func minutes(date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}
