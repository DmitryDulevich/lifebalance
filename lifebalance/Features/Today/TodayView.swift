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
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EEEE, d MMMM"
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

                    if let hero = data.heroTask {
                        HeroFocusCard(
                            title: hero.title,
                            subtitle: TaskDisplay.subtitle(for: hero)
                        ) {
                            focusTarget = FocusNavigationTarget(task: hero)
                        }
                    }

                    HStack(spacing: 8) {
                        StatTile(value: "\(data.completedCountToday)/\(data.totalCountToday)", label: "выполнено")
                        StatTile(value: "\(data.focusMinutesToday) мин", label: "фокуса")
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

                    if !data.overdueTasks.isEmpty {
                        section(title: "Просрочено", titleColor: Palette.overdue, tasks: data.overdueTasks, showOverdue: true)
                    }

                    if !data.todayTasks.isEmpty {
                        section(title: "Запланировано на сегодня", titleColor: Palette.textSecondary, tasks: data.todayTasks)
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
                        section(title: "Выполнено сегодня", titleColor: Palette.textSecondary, tasks: data.doneTasks)
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

    private func section(title: String, titleColor: Color, tasks: [TaskItem], showOverdue: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(titleColor)

            VStack(spacing: 8) {
                ForEach(tasks) { task in
                    TaskRowView(
                        title: task.title,
                        subtitle: TaskDisplay.subtitle(for: task, showOverdueLabel: showOverdue),
                        ringColor: TaskDisplay.ringColor(for: task),
                        isCompleted: task.status == .completed,
                        onToggle: { viewModel.toggleCompletion(task) },
                        onPlay: task.status == .completed ? nil : { focusTarget = FocusNavigationTarget(task: task) }
                    )
                }
            }
        }
    }
}
