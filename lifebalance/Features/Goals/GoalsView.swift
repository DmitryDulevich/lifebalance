import SwiftUI

struct GoalsView: View {
    @State private var viewModel: GoalsViewModel
    let container: AppContainer
    let refreshToken: Int
    @State private var selectedGoal: Goal?

    init(container: AppContainer, refreshToken: Int = 0) {
        self.container = container
        self.refreshToken = refreshToken
        _viewModel = State(initialValue: container.makeGoalsViewModel())
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = .autoupdatingCurrent
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
            .sheet(item: $selectedGoal) { goal in
                GoalDetailView(
                    container: container,
                    goal: goal,
                    lifeAreas: viewModel.lifeAreas,
                    onChanged: { viewModel.load() }
                )
            }
        }
        .task(id: refreshToken) { viewModel.load() }
        .appErrorAlert($viewModel.errorMessage)
    }

    private func goalCard(_ goal: Goal) -> some View {
        let color = goal.lifeArea.map { Color(hex: $0.colorHex) } ?? Palette.accent
        let progress = GoalProgressCalculator.summary(for: goal)

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
                ProgressBarView(progress: progress.fraction, color: color)
                Text("\(progress.percentage)%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.textSecondary)
            }

            HStack {
                Label(
                    "\(progress.completedTaskCount) из \(progress.totalTaskCount) задач",
                    systemImage: "checklist"
                )
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Palette.textSecondary)

                Spacer()

                Button("Открыть") { selectedGoal = goal }
                    .font(.system(size: 12, weight: .semibold))
                    .accessibilityIdentifier("goal.tasks.\(goal.title)")
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
        return parts.isEmpty ? String(localized: "Без сферы") : parts.joined(separator: " · ")
    }

    private func title(for status: GoalStatus) -> String {
        switch status {
        case .active: String(localized: "Активные")
        case .paused: String(localized: "Пауза")
        case .completed: String(localized: "Готово")
        case .archived: String(localized: "Архив")
        }
    }

    private var emptyTitle: String {
        switch viewModel.selectedStatus {
        case .active: String(localized: "Пока нет активных целей")
        case .paused: String(localized: "Нет целей на паузе")
        case .completed: String(localized: "Нет завершённых целей")
        case .archived: String(localized: "Архив пуст")
        }
    }

    private var emptyDescription: String {
        viewModel.selectedStatus == .active
            ? String(localized: "Цель — это измеримый результат. Нажмите «+», чтобы создать первую.")
            : String(localized: "Здесь появятся цели с выбранным статусом.")
    }
}
