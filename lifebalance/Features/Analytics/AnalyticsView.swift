import Charts
import SwiftUI

struct AnalyticsView: View {
    @State private var viewModel: AnalyticsViewModel

    init(container: AppContainer) {
        _viewModel = State(initialValue: container.makeAnalyticsViewModel())
    }

    var body: some View {
        ZStack {
            ScreenBackground()
            content
        }
        .navigationTitle("Аналитика")
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .empty:
            ContentUnavailableView("Нет данных", systemImage: "chart.xyaxis.line")
        case .error(let message):
            ContentUnavailableView(
                "Не удалось загрузить аналитику",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        case .content(let report):
            reportContent(report)
        }
    }

    private func reportContent(_ report: AnalyticsReport) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                periodPicker
                summaryGrid(report)
                dailyFocusChart(report)
                completedTasksChart(report)

                if !report.focusByArea.isEmpty {
                    focusByAreaSection(report.focusByArea)
                }
                goalsSection(report)
                balanceSection(report.balanceHistory)
            }
            .padding(20)
            .padding(.bottom, 40)
        }
    }

    private var periodPicker: some View {
        HStack(spacing: 8) {
            ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                FilterChip(
                    label: period.title,
                    isActive: viewModel.selectedPeriod == period
                ) {
                    viewModel.selectPeriod(period)
                }
                .accessibilityIdentifier("analytics.period.\(period.rawValue)")
            }
        }
    }

    private func summaryGrid(_ report: AnalyticsReport) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            StatTile(value: "\(report.totalFocusMinutes) мин", label: "фокуса")
                .accessibilityIdentifier("analytics.focus_minutes")
            StatTile(value: "\(report.completedFocusSessions)", label: "фокус-сессий")
            StatTile(value: "\(report.completedTasks)", label: "задач выполнено")
                .accessibilityIdentifier("analytics.completed_tasks")
            StatTile(value: "\(report.createdGoals)", label: "целей создано")
            StatTile(value: "\(report.completedGoals)", label: "целей завершено")
                .accessibilityIdentifier("analytics.completed_goals")
        }
    }

    private func dailyFocusChart(_ report: AnalyticsReport) -> some View {
        chartCard(title: "Фокус по дням") {
            Chart(report.daily) { point in
                BarMark(
                    x: .value("День", point.date, unit: .day),
                    y: .value("Минуты", point.focusMinutes)
                )
                .foregroundStyle(Palette.accent.gradient)
                .cornerRadius(4)
            }
            .chartYAxisLabel("мин")
            .frame(height: 170)
        }
    }

    private func completedTasksChart(_ report: AnalyticsReport) -> some View {
        chartCard(title: "Выполненные задачи") {
            Chart(report.daily) { point in
                BarMark(
                    x: .value("День", point.date, unit: .day),
                    y: .value("Задачи", point.completedTasks)
                )
                .foregroundStyle(Color.green.gradient)
                .cornerRadius(4)
            }
            .frame(height: 150)
        }
    }

    private func focusByAreaSection(_ rows: [AnalyticsAreaFocus]) -> some View {
        sectionCard(title: "Фокус по сферам") {
            let maximum = max(1, rows.map(\.minutes).max() ?? 1)
            ForEach(rows) { row in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(row.name)
                        Spacer()
                        Text("\(row.minutes) мин")
                            .foregroundStyle(Palette.textSecondary)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    ProgressBarView(
                        progress: Double(row.minutes) / Double(maximum),
                        color: Color(hex: row.colorHex)
                    )
                }
            }
        }
    }

    private func goalsSection(_ report: AnalyticsReport) -> some View {
        sectionCard(title: "Цели") {
            Text(goalStatusSummary(report.goalCounts))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Palette.textSecondary)

            if report.goals.isEmpty {
                Text("Нет активных целей")
                    .foregroundStyle(Palette.textSecondary)
            } else {
                ForEach(report.goals) { row in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(row.goal.title)
                                .font(.system(size: 13, weight: .semibold))
                            Spacer()
                            Text("\(row.progress.percentage)%")
                                .foregroundStyle(Palette.textSecondary)
                        }
                        ProgressBarView(progress: row.progress.fraction, color: Palette.accent)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func balanceSection(_ points: [AnalyticsBalancePoint]) -> some View {
        if points.isEmpty {
            sectionCard(title: "История баланса") {
                Text("Оцените баланс, чтобы появилась динамика.")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.textSecondary)
            }
        } else {
            chartCard(title: "История баланса") {
                Chart(points) { point in
                    LineMark(
                        x: .value("Дата", point.date),
                        y: .value("Средняя оценка", point.average)
                    )
                    .foregroundStyle(Palette.accent)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Дата", point.date),
                        y: .value("Средняя оценка", point.average)
                    )
                    .foregroundStyle(Palette.accent)
                }
                .chartYScale(domain: 0...10)
                .frame(height: 170)
            }
        }
    }

    private func chartCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        sectionCard(title: title, content: content)
    }

    private func sectionCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Palette.textPrimary)
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Palette.cardBackground)
        )
    }

    private func goalStatusSummary(_ counts: [GoalStatus: Int]) -> String {
        "Активные: \(counts[.active, default: 0]) · Пауза: \(counts[.paused, default: 0]) · Завершённые: \(counts[.completed, default: 0])"
    }
}
