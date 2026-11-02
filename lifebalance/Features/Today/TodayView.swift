import SwiftUI

struct TodayView: View {
    @State private var viewModel: TodayViewModel
    let container: AppContainer
    let refreshToken: Int
    @State private var focusTarget: FocusNavigationTarget?

    init(container: AppContainer, refreshToken: Int = 0) {
        self.container = container
        self.refreshToken = refreshToken
        _viewModel = State(initialValue: container.makeTodayViewModel())
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMMM")
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                content
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $focusTarget) { target in
                FocusTimerView(
                    task: target.task,
                    plannedSeconds: (target.task?.estimateMinutes ?? 25) * 60,
                    container: container
                )
            }
        }
        .task(id: refreshToken) { viewModel.load() }
        .appErrorAlert($viewModel.errorMessage)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .error(let message):
            ContentUnavailableView(
                "Не удалось загрузить",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        case .empty:
            ContentUnavailableView(
                "Нет сфер",
                systemImage: "circle.dashed",
                description: Text("Сферы жизни ещё не выбраны.")
            )
        case .content(let data):
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    planningLinks

                    if let hero = data.heroTask {
                        HeroFocusCard(
                            title: hero.title,
                            subtitle: TaskDisplay.subtitle(for: hero)
                        ) {
                            focusTarget = FocusNavigationTarget(task: hero)
                        }
                    }

                    HStack(spacing: 8) {
                        StatTile(
                            value: "\(data.completedCountToday)/\(data.totalCountToday)",
                            label: String(localized: "выполнено")
                        )
                        StatTile(
                            value: String(localized: "\(data.focusMinutesToday) мин"),
                            label: String(localized: "фокуса")
                        )
                    }

                    if !data.lifeAreas.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(data.lifeAreas) { area in
                                    FilterChip(label: area.name, dotColor: Color(hex: area.colorHex))
                                }
                            }
                        }
                    }

                    if !data.activeGoals.isEmpty {
                        activeGoalsSection(data.activeGoals)
                    }

                    if !data.overdueTasks.isEmpty {
                        section(
                            title: String(localized: "Просрочено"),
                            titleColor: Palette.overdue,
                            tasks: data.overdueTasks,
                            showOverdue: true,
                            canMoveToTomorrow: true
                        )
                    }

                    if !data.todayTasks.isEmpty {
                        section(
                            title: String(localized: "Запланировано на сегодня"),
                            titleColor: Palette.textSecondary,
                            tasks: data.todayTasks
                        )
                    }

                    if data.overdueTasks.isEmpty && data.todayTasks.isEmpty {
                        ContentUnavailableView(
                            "На сегодня ничего не запланировано",
                            systemImage: "checkmark.circle",
                            description: Text("Создайте задачу, чтобы начать день.")
                        )
                        .padding(.top, 20)
                    }

                    if !data.doneTasks.isEmpty {
                        section(
                            title: String(localized: "Выполнено сегодня"),
                            titleColor: Palette.textSecondary,
                            tasks: data.doneTasks
                        )
                    }
                }
                .padding(20)
                .padding(.bottom, 80)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Self.dateFormatter.string(from: .now).capitalized)
                .font(.system(size: 14))
                .foregroundStyle(Palette.textSecondary)
            Text("Сегодня")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Palette.textPrimary)
        }
        .padding(.top, 8)
    }

    private var planningLinks: some View {
        HStack(spacing: 10) {
            NavigationLink {
                WeeklyReviewView(container: container)
            } label: {
                planningCard(title: String(localized: "Обзор недели"), icon: "calendar.badge.checkmark")
            }
            .accessibilityIdentifier("today.weekly_review")

            NavigationLink {
                HabitsView(container: container)
            } label: {
                planningCard(title: String(localized: "Привычки"), icon: "repeat.circle.fill")
            }
            .accessibilityIdentifier("today.habits")
        }
        .buttonStyle(.plain)
    }

    private func planningCard(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Palette.accent)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.cardBackground))
    }

    private func section(
        title: String,
        titleColor: Color,
        tasks: [TaskItem],
        showOverdue: Bool = false,
        canMoveToTomorrow: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(titleColor)
                Spacer()
                if canMoveToTomorrow {
                    Button("Все на завтра") {
                        viewModel.moveAllOverdueToTomorrow()
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .accessibilityIdentifier("today.move_all_overdue")
                }
            }

            VStack(spacing: 8) {
                ForEach(tasks) { task in
                    HStack(spacing: 8) {
                        TaskRowView(
                            title: task.title,
                            subtitle: TaskDisplay.subtitle(
                                for: task,
                                showOverdueLabel: showOverdue,
                                showGoal: true
                            ),
                            ringColor: TaskDisplay.ringColor(for: task),
                            isCompleted: task.status == .completed,
                            onToggle: { viewModel.toggleCompletion(task) },
                            onPlay: task.status == .completed ? nil : {
                                focusTarget = FocusNavigationTarget(task: task)
                            }
                        )

                        if canMoveToTomorrow {
                            Menu {
                                Button("Перенести на завтра") {
                                    viewModel.moveToTomorrow(task)
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Palette.textSecondary)
                                    .frame(width: 44, height: 44)
                            }
                            .accessibilityIdentifier("today.task.menu.\(task.title)")
                        }
                    }
                }
            }
        }
    }

    private func activeGoalsSection(_ goals: [TodayViewModel.GoalSummary]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Активные цели")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(goals) { summary in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(summary.goal.title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Palette.textPrimary)
                                .lineLimit(1)
                                .accessibilityIdentifier("today.goal.\(summary.goal.title)")

                            ProgressBarView(
                                progress: summary.progress.fraction,
                                color: Palette.accent
                            )

                            HStack {
                                Text("\(summary.progress.completedTaskCount) из \(summary.progress.totalTaskCount)")
                                Spacer()
                                Text("\(summary.progress.percentage)%")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Palette.textSecondary)
                        }
                        .padding(14)
                        .frame(width: 220)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Palette.cardBackground)
                        )
                    }
                }
            }
        }
    }
}
