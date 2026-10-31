import SwiftUI

struct BalanceView: View {
    @State private var viewModel: BalanceViewModel

    init(container: AppContainer) {
        _viewModel = State(initialValue: container.makeBalanceViewModel())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Баланс")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(Palette.textPrimary)
                            Text("Последний снимок · сегодня")
                                .font(.system(size: 13))
                                .foregroundStyle(Palette.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        ZStack {
                            BalanceRadarChart(
                                axes: viewModel.radarAxes.map { .init(color: Color(hex: $0.colorHex), value: $0.value) }
                            )
                            .frame(width: 220, height: 220)

                            VStack(spacing: 2) {
                                Text(String(format: "%.1f", viewModel.averageScore))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(Palette.textPrimary)
                                Text("средний балл")
                                    .font(.system(size: 10.5))
                                    .foregroundStyle(Palette.textSecondary)
                            }
                        }

                        VStack(spacing: 8) {
                            ForEach(viewModel.rows) { row in
                                stepperRow(row)
                            }
                        }

                        Text("Оцените каждую сферу от 1 до 10 — колесо покажет, где сейчас перекос")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 280)
                    }
                    .padding(20)
                    .padding(.bottom, 80)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { viewModel.load() }
        .appErrorAlert($viewModel.errorMessage)
    }

    private func stepperRow(_ row: BalanceViewModel.AreaRow) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: row.area.colorHex))
                .frame(width: 10, height: 10)

            Text(row.area.name)
                .font(.system(size: 14.5, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)

            Spacer()

            HStack(spacing: 10) {
                Button {
                    viewModel.adjust(row, delta: -1)
                } label: {
                    Text("−")
                        .font(.system(size: 16))
                        .foregroundStyle(Palette.textPrimary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Palette.softAccentBackground))
                }
                .buttonStyle(.plain)

                Text(row.value == 0 ? "–" : "\(row.value)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Palette.textPrimary)
                    .frame(minWidth: 18)

                Button {
                    viewModel.adjust(row, delta: 1)
                } label: {
                    Text("+")
                        .font(.system(size: 16))
                        .foregroundStyle(Palette.textPrimary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Palette.softAccentBackground))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.cardBackground))
    }
}
