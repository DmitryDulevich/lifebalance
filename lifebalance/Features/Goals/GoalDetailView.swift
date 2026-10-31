import SwiftUI

struct GoalDetailView: View {
    @State private var viewModel: GoalDetailViewModel
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

                        HStack {
                            Text("Задачи цели")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Palette.textPrimary)
                            Spacer()
                            if viewModel.canAddTask {
                                Button {
                                    viewModel.showTaskForm = true
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
                    editingTask: nil,
                    preselectedGoal: viewModel.goal,
                    onSaved: {
                        viewModel.taskWasSaved()
                        onChanged()
                    }
                )
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
