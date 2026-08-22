import SwiftUI

struct CustomAreaSheet: View {
    @Bindable var viewModel: AreaSelectionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Название") {
                    TextField("Например, «Хобби»", text: $viewModel.customNameInput)
                }

                Section("Цвет") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(Palette.sphereSwatches, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .strokeBorder(.primary, lineWidth: viewModel.customColorHex == hex ? 2 : 0)
                                )
                                .onTapGesture { viewModel.customColorHex = hex }
                                .accessibilityLabel("Цвет \(hex)")
                                .accessibilityAddTraits(viewModel.customColorHex == hex ? [.isSelected] : [])
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Иконка") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(Palette.sphereIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: 32, height: 32)
                                .foregroundStyle(viewModel.customIcon == icon ? Color(hex: viewModel.customColorHex) : .secondary)
                                .background(
                                    Circle()
                                        .fill(viewModel.customIcon == icon ? Color(hex: viewModel.customColorHex).opacity(0.15) : .clear)
                                )
                                .onTapGesture { viewModel.customIcon = icon }
                                .accessibilityLabel("Иконка \(icon)")
                                .accessibilityAddTraits(viewModel.customIcon == icon ? [.isSelected] : [])
                        }
                    }
                    .padding(.vertical, 4)
                }

                if let error = viewModel.customAreaErrorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Своя сфера")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
                        viewModel.addCustomArea()
                        if viewModel.customAreaErrorMessage == nil {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
