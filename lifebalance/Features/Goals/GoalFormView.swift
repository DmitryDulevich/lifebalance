import SwiftUI

struct GoalFormView: View {
    @State private var viewModel: GoalFormViewModel
    @Environment(\.dismiss) private var dismiss
    var onSaved: () -> Void

    init(container: AppContainer, lifeAreas: [LifeArea], onSaved: @escaping () -> Void) {
        _viewModel = State(initialValue: GoalFormViewModel(container: container, lifeAreas: lifeAreas))
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Название") {
                    TextField("Например, «Сдать проект»", text: $viewModel.title)
                }

                Section("Сфера") {
                    Picker("Сфера", selection: $viewModel.selectedAreaID) {
                        Text("Без сферы").tag(UUID?.none)
                        ForEach(viewModel.lifeAreas) { area in
                            Text(area.name).tag(Optional(area.id))
                        }
                    }
                }

                Section("Срок") {
                    Toggle("Назначить срок", isOn: $viewModel.hasTargetDate)
                    if viewModel.hasTargetDate {
                        DatePicker("Дата", selection: $viewModel.targetDate, displayedComponents: .date)
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error).foregroundStyle(.red)
                }
            }
            .navigationTitle("Новая цель")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        if viewModel.save() {
                            onSaved()
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
