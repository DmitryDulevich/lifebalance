import SwiftUI
import UIKit

struct ReminderSettingsView: View {
    @State private var viewModel: ReminderSettingsViewModel
    @Environment(\.openURL) private var openURL

    init(container: AppContainer) {
        _viewModel = State(initialValue: container.makeReminderSettingsViewModel())
    }

    var body: some View {
        Form {
            Section("Доступ") {
                LabeledContent("Уведомления", value: authorizationTitle)
                if viewModel.authorizationState == .denied {
                    Button("Открыть настройки iOS") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                }
            }

            Section {
                Toggle("Напоминать перед сроком", isOn: Binding(
                    get: { viewModel.preferences.taskRemindersEnabled },
                    set: { enabled in Task { await viewModel.setTaskRemindersEnabled(enabled) } }
                ))
                if viewModel.preferences.taskRemindersEnabled {
                    Picker("За сколько", selection: $viewModel.preferences.taskLeadMinutes) {
                        Text("В момент срока").tag(0)
                        Text("За 15 минут").tag(15)
                        Text("За 1 час").tag(60)
                        Text("За 1 день").tag(1_440)
                    }
                    .onChange(of: viewModel.preferences.taskLeadMinutes) { _, _ in viewModel.save() }
                }
            } header: {
                Text("Задачи")
            } footer: {
                Text("На заблокированном экране название задачи не показывается.")
            }

            Section("Привычки") {
                Toggle("Ежедневное напоминание", isOn: Binding(
                    get: { viewModel.preferences.habitRemindersEnabled },
                    set: { enabled in Task { await viewModel.setHabitRemindersEnabled(enabled) } }
                ))
                if viewModel.preferences.habitRemindersEnabled {
                    DatePicker(
                        "Время",
                        selection: Binding(
                            get: { viewModel.habitReminderDate },
                            set: { viewModel.habitReminderDate = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                }
            }

            Section("Еженедельный обзор") {
                Toggle("Напоминать об обзоре", isOn: Binding(
                    get: { viewModel.preferences.weeklyReviewEnabled },
                    set: { enabled in Task { await viewModel.setWeeklyReviewEnabled(enabled) } }
                ))
                if viewModel.preferences.weeklyReviewEnabled {
                    Picker("День недели", selection: $viewModel.preferences.weeklyReviewWeekday) {
                        ForEach(1...7, id: \.self) { weekday in
                            Text(Self.weekdaySymbols[weekday - 1]).tag(weekday)
                        }
                    }
                    .onChange(of: viewModel.preferences.weeklyReviewWeekday) { _, _ in viewModel.save() }
                    DatePicker(
                        "Время",
                        selection: Binding(
                            get: { viewModel.weeklyReviewDate },
                            set: { viewModel.weeklyReviewDate = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                }
            }
        }
        .navigationTitle("Напоминания")
        .task { await viewModel.load() }
        .appErrorAlert($viewModel.errorMessage)
    }

    private var authorizationTitle: String {
        switch viewModel.authorizationState {
        case .notDetermined: String(localized: "Не запрашивались")
        case .authorized: String(localized: "Разрешены")
        case .denied: String(localized: "Запрещены")
        }
    }

    private static var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        return formatter.weekdaySymbols
    }
}
