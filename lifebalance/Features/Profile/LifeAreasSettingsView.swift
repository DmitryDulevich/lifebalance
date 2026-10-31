import SwiftUI

struct LifeAreasSettingsView: View {
    @State private var viewModel: LifeAreasSettingsViewModel

    init(container: AppContainer) {
        _viewModel = State(initialValue: container.makeLifeAreasSettingsViewModel())
    }

    var body: some View {
        List {
            Section {
                Text("Используйте от 3 до 8 активных сфер. Скрытая сфера остаётся связана со старыми задачами, целями и оценками.")
                    .font(.footnote)
                    .foregroundStyle(Palette.textSecondary)
            }

            Section("Активные — \(viewModel.activeAreas.count)") {
                ForEach(viewModel.activeAreas) { area in
                    areaRow(area)
                        .contentShape(Rectangle())
                        .onTapGesture { viewModel.startEditing(area) }
                        .swipeActions(edge: .trailing) {
                            Button("Скрыть", role: .destructive) {
                                viewModel.archive(area)
                            }
                        }
                        .accessibilityIdentifier("life_area.active.\(area.name)")
                }
                .onMove(perform: viewModel.move)
            }

            if !viewModel.archivedAreas.isEmpty {
                Section("Архив") {
                    ForEach(viewModel.archivedAreas) { area in
                        HStack {
                            areaRow(area)
                            Spacer()
                            Button("Вернуть") {
                                viewModel.restore(area)
                            }
                            .buttonStyle(.borderless)
                        }
                        .accessibilityIdentifier("life_area.archived.\(area.name)")
                    }
                }
            }
        }
        .navigationTitle("Сферы жизни")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                EditButton()
                Button {
                    viewModel.startAdding()
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(!viewModel.canAddArea)
                .accessibilityIdentifier("life_area.add")
            }
        }
        .task { viewModel.load() }
        .sheet(isPresented: $viewModel.isFormPresented) {
            LifeAreaFormView(viewModel: viewModel)
        }
        .appErrorAlert($viewModel.errorMessage)
    }

    private func areaRow(_ area: LifeArea) -> some View {
        HStack(spacing: 12) {
            Image(systemName: area.icon)
                .foregroundStyle(Color(hex: area.colorHex))
                .frame(width: 28)
            Text(area.name)
        }
    }
}

private struct LifeAreaFormView: View {
    @Bindable var viewModel: LifeAreasSettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Название") {
                    TextField("Например, «Хобби»", text: $viewModel.formName)
                        .accessibilityIdentifier("life_area.name")
                }

                Section("Цвет") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(Palette.sphereSwatches, id: \.self) { hex in
                            Button {
                                viewModel.formColorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 32, height: 32)
                                    .overlay(Circle().strokeBorder(.primary, lineWidth: viewModel.formColorHex == hex ? 2 : 0))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Цвет \(hex)")
                        }
                    }
                }

                Section("Иконка") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(Palette.sphereIcons, id: \.self) { icon in
                            Button {
                                viewModel.formIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .frame(width: 32, height: 32)
                                    .foregroundStyle(viewModel.formIcon == icon ? Color(hex: viewModel.formColorHex) : .secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Иконка \(icon)")
                        }
                    }
                }

                if let error = viewModel.formErrorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle(viewModel.editingArea == nil ? "Новая сфера" : "Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        viewModel.isFormPresented = false
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        if viewModel.saveForm() {
                            dismiss()
                        }
                    }
                    .accessibilityIdentifier("life_area.save")
                }
            }
        }
    }
}
