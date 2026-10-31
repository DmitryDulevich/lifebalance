import SwiftUI

struct GoalsView: View {
    @State private var viewModel: GoalsViewModel
    let container: AppContainer
    let refreshToken: Int

    init(container: AppContainer, refreshToken: Int = 0) {
        self.container = container
        self.refreshToken = refreshToken
        _viewModel = State(initialValue: container.makeGoalsViewModel())
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
                                viewModel.startCreating()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(Palette.accent)
                            }
                            .accessibilityIdentifier("goals.add")
                        }
                        .padding(.top, 8)

                        statusFilters

                        if viewModel.filteredGoals.isEmpty {
                            ContentUnavailableView(
                                emptyTitle,
                                systemImage: "target",
                                description: Text(emptyDescription)
                            )
                            .padding(.top, 40)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(viewModel.filteredGoals) { goal in
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
                GoalFormView(
                    container: container,
                    lifeAreas: viewModel.lifeAreas,
                    editingGoal: viewModel.editingGoal,
                    onSaved: { viewModel.load() }
                )
            }
        }
        .task(id: refreshToken) { viewModel.load() }
        .appErrorAlert($viewModel.errorMessage)
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
                Spacer()
                goalActions(goal)
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

    private var statusFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GoalStatus.allCases, id: \.self) { status in
                    FilterChip(
                        label: "\(title(for: status)) · \(viewModel.count(for: status))",
                        isActive: viewModel.selectedStatus == status
                    ) {
                        viewModel.selectedStatus = status
                    }
                    .accessibilityIdentifier("goals.filter.\(status.rawValue)")
                }
            }
        }
    }

    private func goalActions(_ goal: Goal) -> some View {
        Menu {
            if goal.status != .archived {
                Button("Редактировать") { viewModel.startEditing(goal) }
            }

            switch goal.status {
            case .active:
                Button("Поставить на паузу") { viewModel.setStatus(.paused, for: goal) }
                Button("Завершить") { viewModel.setStatus(.completed, for: goal) }
                Button("Архивировать", role: .destructive) { viewModel.setStatus(.archived, for: goal) }
            case .paused:
                Button("Возобновить") { viewModel.setStatus(.active, for: goal) }
                Button("Завершить") { viewModel.setStatus(.completed, for: goal) }
                Button("Архивировать", role: .destructive) { viewModel.setStatus(.archived, for: goal) }
            case .completed:
                Button("Вернуть в активные") { viewModel.setStatus(.active, for: goal) }
                Button("Архивировать", role: .destructive) { viewModel.setStatus(.archived, for: goal) }
            case .archived:
                Button("Восстановить") { viewModel.setStatus(.active, for: goal) }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(Palette.textSecondary)
        }
        .accessibilityIdentifier("goal.menu.\(goal.title)")
    }

    private func captionText(_ goal: Goal) -> String {
        var parts: [String] = []
        if let area = goal.lifeArea { parts.append(area.name) }
        if let targetDate = goal.targetDate {
            parts.append(Self.relativeFormatter.localizedString(for: targetDate, relativeTo: .now))
        }
        return parts.isEmpty ? "Без сферы" : parts.joined(separator: " · ")
    }

    private func title(for status: GoalStatus) -> String {
        switch status {
        case .active: "Активные"
        case .paused: "Пауза"
        case .completed: "Готово"
        case .archived: "Архив"
        }
    }

    private var emptyTitle: String {
        switch viewModel.selectedStatus {
        case .active: "Пока нет активных целей"
        case .paused: "Нет целей на паузе"
        case .completed: "Нет завершённых целей"
        case .archived: "Архив пуст"
        }
    }

    private var emptyDescription: String {
        viewModel.selectedStatus == .active
            ? "Цель — это измеримый результат. Нажмите «+», чтобы создать первую."
            : "Здесь появятся цели с выбранным статусом."
    }
}
