import SwiftUI

struct GoalsView: View {
    @State private var viewModel: GoalsViewModel
    let container: AppContainer

    init(container: AppContainer) {
        self.container = container
        _viewModel = State(initialValue: GoalsViewModel(container: container))
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.unitsStyle = .full
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Цели")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(Palette.textPrimary)
                            Spacer()
                            Button {
                                viewModel.showGoalForm = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(Palette.accent)
                            }
                        }
                        .padding(.top, 8)

                        if viewModel.goals.isEmpty {
                            ContentUnavailableView(
                                "Пока нет целей",
                                systemImage: "target",
                                description: Text("Цель — это измеримый результат, а не разовая задача. Нажмите «+», чтобы создать первую.")
                            )
                            .padding(.top, 40)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(viewModel.goals) { goal in
                                    goalCard(goal)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 80)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $viewModel.showGoalForm) {
                GoalFormView(container: container, lifeAreas: viewModel.lifeAreas, onSaved: { viewModel.load() })
            }
        }
        .task { viewModel.load() }
    }

    private func goalCard(_ goal: Goal) -> some View {
        let color = goal.lifeArea.map { Color(hex: $0.colorHex) } ?? Palette.accent
        let progress = GoalProgressCalculator.progress(for: goal)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(captionText(goal))
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.textSecondary)
            }

            Text(goal.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Palette.textPrimary)

            HStack(spacing: 10) {
                ProgressBarView(progress: progress, color: color)
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Palette.cardBackground))
    }

    private func captionText(_ goal: Goal) -> String {
        var parts: [String] = []
        if let area = goal.lifeArea { parts.append(area.name) }
        if let targetDate = goal.targetDate {
            parts.append(Self.relativeFormatter.localizedString(for: targetDate, relativeTo: .now))
        }
        return parts.isEmpty ? "Без сферы" : parts.joined(separator: " · ")
    }
}
