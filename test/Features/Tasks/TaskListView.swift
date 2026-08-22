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
                                    TaskRowView(
                                        title: task.title,
                                        subtitle: TaskDisplay.subtitle(for: task, showOverdueLabel: group.title == "Просрочено"),
                                        ringColor: TaskDisplay.ringColor(for: task),
                                        isCompleted: false,
                                        onToggle: { viewModel.toggleCompletion(task) },
                                        onPlay: { onPlay(task) }
                                    )
                                    .contextMenu {
                                        Button("Редактировать") { onEdit(task) }
                                        Button("Удалить", role: .destructive) { viewModel.delete(task) }
                                    }
                                }
                            }
                        }
                    }
                }

                if groups.allSatisfy({ $0.tasks.isEmpty }) {
                    ContentUnavailableView(
                        "Нет задач",
                        systemImage: "checklist",
                        description: Text("Нажмите «+», чтобы создать первую задачу.")
                    )
                    .padding(.top, 20)
                }
            }
            .padding(.bottom, 80)
        }
    }

    private func groupedTasks() -> [Group] {
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
}
