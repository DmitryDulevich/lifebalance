import SwiftUI

struct TaskListView: View {
    let viewModel: TasksViewModel
    var onPlay: (TaskItem) -> Void
    var onEdit: (TaskItem) -> Void

    private struct Group {
        let title: String
        let tasks: [TaskItem]
    }

    var body: some View {
        let groups = groupedTasks()

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(groups, id: \.title) { group in
                    if !group.tasks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(group.title == "Просрочено" ? Palette.overdue : Palette.textSecondary)

                            VStack(spacing: 8) {
                                ForEach(group.tasks) { task in
                                    HStack(spacing: 8) {
                                        TaskRowView(
                                            title: task.title,
                                            subtitle: TaskDisplay.subtitle(
                                                for: task,
                                                showOverdueLabel: group.title == "Просрочено",
                                                showGoal: true
                                            ),
                                            ringColor: TaskDisplay.ringColor(for: task),
                                            isCompleted: task.status == .completed,
                                            onToggle: {
                                                if task.status != .archived {
                                                    viewModel.toggleCompletion(task)
                                                }
                                            },
                                            onPlay: task.status == .active ? { onPlay(task) } : nil
                                        )
                                        .disabled(task.status == .archived)

                                        taskMenu(task)
                                    }
                                }
                            }
                        }
                    }
                }

                if groups.allSatisfy({ $0.tasks.isEmpty }) {
                    ContentUnavailableView(
                        emptyTitle,
                        systemImage: "checklist",
                        description: Text(emptyDescription)
                    )
                    .padding(.top, 20)
                }
            }
            .padding(.bottom, 80)
        }
    }

    private func groupedTasks() -> [Group] {
        if viewModel.selectedStatus == .completed {
            return [Group(title: "Выполненные", tasks: viewModel.filteredTasks)]
        }
        if viewModel.selectedStatus == .archived {
            return [Group(title: "Архив", tasks: viewModel.filteredTasks)]
        }

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday
        let dayAfterTomorrowStart = calendar.date(byAdding: .day, value: 2, to: startOfToday) ?? tomorrowStart

        let tasks = viewModel.filteredTasks
        let byDueDate: (TaskItem, TaskItem) -> Bool = { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }

        let overdue = tasks.filter { ($0.dueDate ?? .distantFuture) < startOfToday }.sorted(by: byDueDate)
        let today = tasks.filter { ($0.dueDate.map { $0 >= startOfToday && $0 < tomorrowStart }) ?? false }.sorted(by: byDueDate)
        let tomorrow = tasks.filter { ($0.dueDate.map { $0 >= tomorrowStart && $0 < dayAfterTomorrowStart }) ?? false }.sorted(by: byDueDate)
        let later = tasks.filter { ($0.dueDate.map { $0 >= dayAfterTomorrowStart }) ?? false }.sorted(by: byDueDate)
        let noDate = tasks.filter { $0.dueDate == nil }

        return [
            Group(title: "Просрочено", tasks: overdue),
            Group(title: "Сегодня", tasks: today),
            Group(title: "Завтра", tasks: tomorrow),
            Group(title: "Позже", tasks: later),
            Group(title: "Без даты", tasks: noDate)
        ]
    }

    @ViewBuilder
    private func taskMenu(_ task: TaskItem) -> some View {
        Menu {
            switch task.status {
            case .active:
                Button("Редактировать") { onEdit(task) }
                Button("Выполнить") { viewModel.setStatus(.completed, for: task) }
                Button("Архивировать", role: .destructive) { viewModel.setStatus(.archived, for: task) }
            case .completed:
                Button("Редактировать") { onEdit(task) }
                Button("Вернуть в активные") { viewModel.setStatus(.active, for: task) }
                Button("Архивировать", role: .destructive) { viewModel.setStatus(.archived, for: task) }
            case .archived:
                Button("Восстановить") { viewModel.setStatus(.active, for: task) }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 20))
                .foregroundStyle(Palette.textSecondary)
                .frame(width: 44, height: 44)
        }
        .accessibilityIdentifier("task.menu.\(task.title)")
    }

    private var emptyTitle: String {
        switch viewModel.selectedStatus {
        case .active: "Нет активных задач"
        case .completed: "Нет выполненных задач"
        case .archived: "Архив пуст"
        }
    }

    private var emptyDescription: String {
        viewModel.selectedStatus == .active
            ? "Нажмите «+», чтобы создать первую задачу."
            : "Здесь появятся задачи с выбранным статусом."
    }
}
