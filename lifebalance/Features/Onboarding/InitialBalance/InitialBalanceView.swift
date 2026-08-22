import SwiftUI

struct InitialBalanceView: View {
    @State private var viewModel: InitialBalanceViewModel
    let onFinished: () -> Void

    init(container: AppContainer, onFinished: @escaping () -> Void) {
        _viewModel = State(initialValue: InitialBalanceViewModel(container: container))
        self.onFinished = onFinished
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Оцени текущий баланс")
                            .font(.title2.bold())
                            .foregroundStyle(Palette.textPrimary)
                        Text("Оценивай удовлетворённость сферой, а не количество задач в ней.")
                            .font(.subheadline)
                            .foregroundStyle(Palette.textSecondary)
                    }

                    ForEach(viewModel.drafts) { draft in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: draft.area.icon)
                                    .foregroundStyle(Color(hex: draft.area.colorHex))
                                Text(draft.area.name)
                                    .font(.headline)
                                    .foregroundStyle(Palette.textPrimary)
                            }

                            RatingScaleView(
                                value: Binding(
                                    get: { viewModel.binding(for: draft.id) },
                                    set: { viewModel.setValue($0, for: draft.id) }
                                ),
                                tint: Color(hex: draft.area.colorHex)
                            )

                            TextField(
                                "Заметка (необязательно)",
                                text: Binding(
                                    get: { draft.note },
                                    set: { viewModel.setNote($0, for: draft.id) }
                                )
                            )
                            .textFieldStyle(.roundedBorder)
                            .font(.footnote)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Palette.cardBackground)
                        )
                    }
                }
                .padding(20)
            }

            VStack(spacing: 12) {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button("Сохранить") {
                    if viewModel.save() {
                        onFinished()
                    }
                }
                .buttonStyle(.primary(isEnabled: viewModel.canSave))
                .disabled(!viewModel.canSave)

                Button("Пропустить") {
                    if viewModel.skip() {
                        onFinished()
                    }
                }
                .font(.subheadline)
                .foregroundStyle(Palette.textSecondary)
            }
            .padding(20)
            .background(Palette.cardBackground.opacity(0.9))
        }
        .task {
            viewModel.loadAreas()
        }
    }
}
