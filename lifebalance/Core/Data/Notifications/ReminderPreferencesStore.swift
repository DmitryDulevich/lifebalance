import Foundation

@MainActor
final class ReminderPreferencesStore {
    private let defaults: UserDefaults
    private let key = "reminder-preferences.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> ReminderPreferences {
        guard let data = defaults.data(forKey: key),
              let value = try? JSONDecoder().decode(ReminderPreferences.self, from: data) else {
            return ReminderPreferences()
        }
        return value
    }

    func save(_ preferences: ReminderPreferences) throws {
        let data = try JSONEncoder().encode(preferences)
        defaults.set(data, forKey: key)
    }
}
