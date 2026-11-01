import SwiftUI

struct AreaSelectionView: View {
    @State private var viewModel: AreaSelectionViewModel
    let onContinue: () -> Void

    init(container: AppContainer, onContinue: @escaping () -> Void) {
        _viewModel = State(initialValue: container.makeAreaSelectionViewModel())
        self.onContinue = onContinue
    }

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Выбери сферы жизни")
                            .font(.title2.bold())
                            .foregroundStyle(Palette.textPrimary)
                        Text("Выбери от 3 до 8 сфер. Их можно будет изменить позже.")
                            .font(.subheadline)
                            .foregroundStyle(Palette.textSecondary)
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.presets) { preset in
                            SphereCard(
                                name: preset.name,
                                icon: preset.icon,
                                color: Color(hex: preset.colorHex),
                                isSelected: viewModel.selectedPresetIDs.contains(preset.id)
                            ) {
                                viewModel.togglePreset(preset)
                            }
                            .accessibilityIdentifier("area.preset.\(preset.name)")
                        }

                        ForEach(viewModel.customAreas) { area in
                            SphereCard(
                                name: area.name,
                                icon: area.icon,
                                color: Color(hex: area.colorHex),
                                isSelected: viewModel.selectedCustomIDs.contains(area.id)
                            ) {
                                viewModel.toggleCustom(area)
                            }
                            .contextMenu {
                                Button("Удалить", role: .destructive) {
                                    viewModel.removeCustom(area)
                                }
                            }
                        }

                        Button {
                            viewModel.isAddingCustomArea = true
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                Text("Своя сфера")
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                    .foregroundStyle(.tertiary)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }

            VStack(spacing: 12) {
                if viewModel.selectedCount < 3 {
                    Text("Выберите ещё \(3 - viewModel.selectedCount) \(remainingWord)")
                        .font(.footnote)
                        .foregroundStyle(Palette.textSecondary)
                } else {
                    Text("Выбрано: \(viewModel.selectedCount)")
                        .font(.footnote)
                        .foregroundStyle(Palette.textSecondary)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button("Продолжить") {
                    if viewModel.continueTapped() {
                        onContinue()
                    }
                }
                .buttonStyle(.primary(isEnabled: viewModel.canContinue))
                .disabled(!viewModel.canContinue)
                .accessibilityIdentifier("onboarding.areas.continue")
            }
            .padding(20)
            .background(Palette.cardBackground.opacity(0.9))
        }
        .sheet(isPresented: $viewModel.isAddingCustomArea) {
            CustomAreaSheet(viewModel: viewModel)
        }
    }

    private var remainingWord: String {
        (3 - viewModel.selectedCount) == 1
            ? String(localized: "сферу")
            : String(localized: "сферы")
    }
}
