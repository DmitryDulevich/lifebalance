import SwiftUI

struct HabitsView: View {
    @State private var viewModel: HabitsViewModel
    @State private var showCreate = false

    init(container: AppContainer) {
        _viewModel = State(initialValue: container.makeHabitsViewModel())
    }

    var body: some View {
        List {
            Section("Планирование") {
                NavigationLink {
                    RecurringTasksView(repository: viewModel.recurringTaskRepository)
                } label: {
                    Label("Повторяющиеся задачи", systemImage: "calendar.badge.clock")
                }
            }

            if viewModel.habits.isEmpty {
                ContentUnavailableView(
                    "Нет привычек",
                    systemImage: "repeat.circle",
                    description: Text("Добавьте небольшое регулярное действие.")
                )
            } else {
                Section("Активные") {
                    ForEach(viewModel.habits.filter { $0.habit.isActive }) { item in
                        habitRow(item)
                    }
                }
                if viewModel.habits.contains(where: { !$0.habit.isActive }) {
                    Section("На паузе") {
                        ForEach(viewModel.habits.filter { !$0.habit.isActive }) { item in
                            habitRow(item)
                        }
                    }
                }
            }
        }
        .navigationTitle("Привычки")
        .toolbar {
            Button { showCreate = true } label: { Image(systemName: "plus") }
                .accessibilityIdentifier("habits.add")
        }
        .sheet(isPresented: $showCreate) {
            HabitFormView(lifeAreas: viewModel.lifeAreas) { title, target, areaID in
                if viewModel.create(title: title, targetPerWeek: target, areaID: areaID) {
                    showCreate = false
                }
            }
        }
        .task { viewModel.load() }
        .appErrorAlert($viewModel.errorMessage)
    }

    private func habitRow(_ item: HabitsViewModel.HabitProgress) -> some View {
        HStack(spacing: 12) {
            Button { viewModel.toggleToday(item.habit) } label: {
                Image(systemName: item.isDoneToday ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26))
                    .foregroundStyle(item.isDoneToday ? Palette.accent : Palette.textSecondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.habit.title).font(.headline)
                ProgressView(value: item.fraction)
                    .tint(Palette.accent)
                HStack {
                    Text("\(item.completedThisWeek) из \(item.habit.targetPerWeek) за неделю")
                    Spacer()
                    Text("Серия: \(item.currentStreak)")
                }
                .font(.caption)
                .foregroundStyle(Palette.textSecondary)
            }

            Menu {
                Button(item.habit.isActive ? "Поставить на паузу" : "Возобновить") {
                    viewModel.toggleActive(item.habit)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct HabitFormView: View {
    let lifeAreas: [LifeArea]
    let onSave: (String, Int, UUID?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var target = 5
    @State private var areaID: UUID?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Название привычки", text: $title)
                    .accessibilityIdentifier("habit.title")
                Stepper("\(target) раз в неделю", value: $target, in: 1...7)
                Picker("Сфера", selection: $areaID) {
                    Text("Без сферы").tag(UUID?.none)
                    ForEach(lifeAreas) { Text($0.name).tag(Optional($0.id)) }
                }
            }
            .navigationTitle("Новая привычка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { onSave(title, target, areaID) }
                        .accessibilityIdentifier("habit.save")
                }
            }
        }
    }
}
