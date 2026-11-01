import SwiftUI

struct TasksView: View {
    @State private var viewModel: TasksViewModel
    let container: AppContainer
    let refreshToken: Int
    @State private var focusTarget: FocusNavigationTarget?

    init(container: AppContainer, refreshToken: Int = 0) {
        self.container = container
        self.refreshToken = refreshToken
        _viewModel = State(initialValue: container.makeTasksViewModel())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Задачи")
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
                        .accessibilityIdentifier("tasks.add")
                    }

                    statusFilters

                    if viewModel.selectedStatus == .active {
                        SegmentedToggle(
                            options: [String(localized: "Список"), String(localized: "Матрица")],
                            selection: $viewModel.viewMode
                        )
                    }

                    TextField("Поиск задач", text: $viewModel.searchText)
                        .padding(11)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Palette.cardBackground))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: String(localized: "Все"), isActive: viewModel.selectedAreaID == nil) {
                                viewModel.selectedAreaID = nil
                            }
                            ForEach(viewModel.lifeAreas) { area in
                                FilterChip(
                                    label: area.name,
                                    dotColor: Color(hex: area.colorHex),
                                    isActive: viewModel.selectedAreaID == area.id
                                ) {
                                    viewModel.selectedAreaID = area.id
                                }
                            }
                        }
                    }

                    if !viewModel.goals.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(
                                    label: String(localized: "Все цели"),
                                    isActive: viewModel.selectedGoalID == nil
                                ) {
                                    viewModel.selectedGoalID = nil
                                }
                                .accessibilityIdentifier("tasks.goal.all")

                                ForEach(viewModel.goals) { goal in
                                    FilterChip(
                                        label: goal.title,
                                        isActive: viewModel.selectedGoalID == goal.id
                                    ) {
                                        viewModel.selectedGoalID = goal.id
                                    }
                                    .accessibilityIdentifier("tasks.goal.\(goal.id.uuidString)")
                                }
                            }
                        }
                    }

                    if viewModel.selectedStatus != .active || viewModel.viewMode == 0 {
                        TaskListView(
                            viewModel: viewModel,
                            onPlay: { focusTarget = FocusNavigationTarget(task: $0) },
                            onEdit: { viewModel.startEditing($0) }
                        )
                    } else {
                        TaskMatrixView(
                            viewModel: viewModel,
                            onEdit: { viewModel.startEditing($0) }
                        )
                    }
                }
                .padding(20)
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
            .sheet(isPresented: $viewModel.showTaskForm) {
                TaskFormView(
                    container: container,
                    lifeAreas: viewModel.lifeAreas,
                    goals: viewModel.formGoals,
                    editingTask: viewModel.editingTask,
                    onSaved: { viewModel.load() }
                )
            }
        }
        .task(id: refreshToken) { viewModel.load() }
        .appErrorAlert($viewModel.errorMessage)
    }

    private var statusFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TaskStatus.allCases, id: \.self) { status in
                    FilterChip(
                        label: "\(title(for: status)) · \(viewModel.count(for: status))",
                        isActive: viewModel.selectedStatus == status
                    ) {
                        viewModel.selectedStatus = status
                    }
                    .accessibilityIdentifier("tasks.filter.\(status.rawValue)")
                }
            }
        }
    }

    private func title(for status: TaskStatus) -> String {
        switch status {
        case .active: String(localized: "Активные")
        case .completed: String(localized: "Выполненные")
        case .archived: String(localized: "Архив")
        }
    }
}
