import SwiftUI

struct GoalDetailView: View {
    @State private var viewModel: GoalDetailViewModel
    @State private var taskPendingDeletion: TaskItem?
    @Environment(\.dismiss) private var dismiss

    let container: AppContainer
    let lifeAreas: [LifeArea]
    var onChanged: () -> Void

    init(
        container: AppContainer,
        goal: Goal,
        lifeAreas: [LifeArea],
        onChanged: @escaping () -> Void
    ) {
        self.container = container
        self.lifeAreas = lifeAreas
        self.onChanged = onChanged
        _viewModel = State(initialValue: container.makeGoalDetailViewModel(goal: goal))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        progressCard

                        if viewModel.goal.status == .archived {
                            Label(
                                "Архивная цель доступна только для просмотра",
                                systemImage: "archivebox.fill"
                            )
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Palette.textSecondary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Palette.cardBackground)
                            )
                        }

                        HStack {
                            Text("Задачи цели")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Palette.textPrimary)
                            Spacer()
                            if viewModel.canAddTask {
                                Button {
                                    viewModel.startCreatingTask()
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                }
                                .accessibilityIdentifier("goal.task.add")
                            }
                        }

                        if viewModel.tasks.isEmpty {
                            ContentUnavailableView(
                                "Нет связанных задач",
                                systemImage: "checklist",
                                description: Text("Добавьте первый конкретный шаг к этой цели.")
                            )
                            .padding(.top, 24)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(viewModel.tasks) { task in
                                    TaskRowView(
                                        title: task.title,
                                        subtitle: TaskDisplay.subtitle(for: task),
                                        ringColor: TaskDisplay.ringColor(for: task),
                                        isCompleted: task.status == .completed,
                                        onToggle: {
                                            viewModel.toggleCompletion(task)
                                            onChanged()
                                        }
                                    )
                                    .disabled(!viewModel.canModifyTasks)
                                    .contextMenu {
                                        if viewModel.canModifyTasks {
                                            Button("Редактировать") {
                                                viewModel.startEditing(task)
                                            }
                                            Button("Удалить", role: .destructive) {
                                                taskPendingDeletion = task
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(viewModel.goal.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
            .sheet(isPresented: $viewModel.showTaskForm) {
                TaskFormView(
                    container: container,
                    lifeAreas: lifeAreas,
                    goals: [viewModel.goal],
                    editingTask: viewModel.editingTask,
                    preselectedGoal: viewModel.editingTask == nil ? viewModel.goal : nil,
                    onSaved: {
                        viewModel.taskWasSaved()
                        onChanged()
                    }
                )
            }
            .confirmationDialog(
                "Все задачи выполнены",
                isPresented: $viewModel.showCompletionPrompt,
                titleVisibility: .visible
            ) {
                Button("Завершить цель") {
                    viewModel.completeGoal()
                    onChanged()
                }
                Button("Не завершать", role: .cancel) {
                    viewModel.keepGoalOpen()
                }
            } message: {
                Text("Отметить цель как завершённую?")
            }
            .confirmationDialog(
                "Удалить задачу?",
                isPresented: Binding(
                    get: { taskPendingDeletion != nil },
                    set: { if !$0 { taskPendingDeletion = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Удалить", role: .destructive) {
                    guard let task = taskPendingDeletion else { return }
                    viewModel.delete(task)
                    taskPendingDeletion = nil
                    onChanged()
                }
                Button("Отмена", role: .cancel) {
                    taskPendingDeletion = nil
                }
            } message: {
                Text(taskPendingDeletion?.title ?? "")
            }
        }
        .appErrorAlert($viewModel.errorMessage)
    }

    private var progressCard: some View {
        let progress = viewModel.progress

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Прогресс")
                    .font(.system(size: 17, weight: .bold))
                Spacer()
                Text("\(progress.percentage)%")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Palette.accent)
                    .accessibilityIdentifier("goal.progress.percentage")
            }

            ProgressBarView(progress: progress.fraction, color: Palette.accent)

            Text("\(progress.completedTaskCount) из \(progress.totalTaskCount) задач выполнено")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.textSecondary)
                .accessibilityIdentifier("goal.progress.count")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Palette.cardBackground)
        )
    }
}
