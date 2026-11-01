import SwiftUI

struct TaskFormView: View {
    @State private var viewModel: TaskFormViewModel
    @Environment(\.dismiss) private var dismiss
    var onSaved: () -> Void

    init(
        container: AppContainer,
        lifeAreas: [LifeArea],
        goals: [Goal],
        editingTask: TaskItem?,
        preselectedGoal: Goal? = nil,
        onSaved: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: container.makeTaskFormViewModel(
            lifeAreas: lifeAreas,
            goals: goals,
            editingTask: editingTask,
            preselectedGoal: preselectedGoal
        ))
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Название") {
                    TextField("Название задачи", text: $viewModel.title)
                        .accessibilityIdentifier("task.title")
                }

                Section("Заметка") {
                    TextField("Необязательно", text: $viewModel.note, axis: .vertical)
                }

                Section("Сфера") {
                    Picker("Сфера", selection: $viewModel.selectedAreaID) {
                        Text("Без сферы").tag(UUID?.none)
                        ForEach(viewModel.lifeAreas) { area in
                            Text(area.name).tag(Optional(area.id))
                        }
                    }
                }

                if !viewModel.goals.isEmpty {
                    Section("Цель") {
                        Picker("Цель", selection: $viewModel.selectedGoalID) {
                            Text("Без цели").tag(UUID?.none)
                            ForEach(viewModel.goals) { goal in
                                Text(goal.title).tag(Optional(goal.id))
                            }
                        }
                    }
                }

                Section("Срок") {
                    Toggle("Назначить дату", isOn: $viewModel.hasDueDate)
                    if viewModel.hasDueDate {
                        DatePicker(
                            "Дата",
                            selection: Binding(get: { viewModel.dueDate ?? .now }, set: { viewModel.dueDate = $0 }),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                Section("Матрица Эйзенхауэра") {
                    Toggle("Важно", isOn: Binding(get: { viewModel.important ?? false }, set: { viewModel.important = $0 }))
                    Toggle("Срочно", isOn: Binding(get: { viewModel.urgent ?? false }, set: { viewModel.urgent = $0 }))
                }

                Section("Длительность") {
                    TextField("Минут", text: $viewModel.estimateMinutesText)
                        .keyboardType(.numberPad)
                }

                if let error = viewModel.errorMessage {
                    Text(error).foregroundStyle(.red)
                }
            }
            .navigationTitle(
                viewModel.isEditing ? String(localized: "Задача") : String(localized: "Новая задача")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        if viewModel.save() {
                            onSaved()
                            dismiss()
                        }
                    }
                    .accessibilityIdentifier("task.save")
                }
            }
        }
    }
}
