import SwiftUI

struct TasksView: View {
    @State private var viewModel: TasksViewModel
    let container: AppContainer
    @State private var focusTarget: FocusNavigationTarget?

    init(container: AppContainer) {
        self.container = container
        _viewModel = State(initialValue: TasksViewModel(container: container))
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
                    }

                    SegmentedToggle(options: ["Список", "Матрица"], selection: $viewModel.viewMode)

                    TextField("Поиск задач", text: $viewModel.searchText)
                        .padding(11)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Palette.cardBackground))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "Все", isActive: viewModel.selectedAreaID == nil) {
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

                    if viewModel.viewMode == 0 {
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
                    goals: viewModel.goals,
                    editingTask: viewModel.editingTask,
                    onSaved: { viewModel.load() }
                )
            }
        }
        .task { viewModel.load() }
    }
}
