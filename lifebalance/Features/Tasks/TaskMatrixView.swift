import SwiftUI

struct TaskMatrixView: View {
    let viewModel: TasksViewModel
    var onEdit: (TaskItem) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("МАТРИЦА ЭЙЗЕНХАУЭРА")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Palette.textSecondary)
                    .frame(maxWidth: .infinity)

                HStack(spacing: 8) {
                    Spacer().frame(width: 18)
                    columnHeader("СРОЧНО")
                    columnHeader("НЕ СРОЧНО")
                }

                HStack(alignment: .top, spacing: 6) {
                    VStack(spacing: 0) {
                        verticalLabel("ВАЖНО")
                        verticalLabel("НЕ ВАЖНО")
                    }
                    .frame(width: 18)

                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            quadrant(title: "СДЕЛАТЬ", color: Palette.quadrantDo, tasks: doTasks, important: true, urgent: true)
                            quadrant(title: "ЗАПЛАНИРОВАТЬ", color: Palette.quadrantSchedule, tasks: scheduleTasks, important: true, urgent: false)
                        }
                        HStack(spacing: 8) {
                            quadrant(title: "ДЕЛЕГИРОВАТЬ / СОКРАТИТЬ", color: Palette.quadrantDelegate, tasks: delegateTasks, important: false, urgent: true)
                            quadrant(
                                title: "УДАЛИТЬ / ОГРАНИЧИТЬ",
                                color: Palette.textSecondary,
                                tasks: eliminateTasks,
                                important: false,
                                urgent: false,
                                borderColor: Palette.quadrantEliminateBorder
                            )
                        }
                    }
                }

                inboxSection
            }
            .padding(.bottom, 80)
        }
    }

    private var doTasks: [TaskItem] { viewModel.filteredTasks.filter { $0.important == true && $0.urgent == true } }
    private var scheduleTasks: [TaskItem] { viewModel.filteredTasks.filter { $0.important == true && $0.urgent == false } }
    private var delegateTasks: [TaskItem] { viewModel.filteredTasks.filter { $0.important == false && $0.urgent == true } }
    private var eliminateTasks: [TaskItem] { viewModel.filteredTasks.filter { $0.important == false && $0.urgent == false } }
    private var inboxTasks: [TaskItem] { viewModel.filteredTasks.filter { $0.important == nil || $0.urgent == nil } }

    private func columnHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .tracking(0.4)
            .foregroundStyle(Palette.textSecondary)
            .frame(maxWidth: .infinity)
    }

    private func verticalLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .tracking(0.4)
            .foregroundStyle(Palette.textSecondary)
            .fixedSize()
            .rotationEffect(.degrees(-90))
            .frame(maxWidth: 18, maxHeight: .infinity)
    }

    private func quadrant(
        title: String,
        color: Color,
        tasks: [TaskItem],
        important: Bool,
        urgent: Bool,
        borderColor: Color? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)

            VStack(spacing: 6) {
                ForEach(tasks) { task in
                    matrixChip(task, important: important, urgent: urgent)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.cardBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(borderColor ?? color.opacity(0.25), lineWidth: 1.5)
        )
        .dropDestination(for: String.self) { items, _ in
            return handleDrop(items, important: important, urgent: urgent)
        }
    }

    private func matrixChip(_ task: TaskItem, important: Bool?, urgent: Bool?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(task.title)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(2)
            if let area = task.lifeArea {
                Text(area.name)
                    .font(.system(size: 10.5))
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Palette.softAccentBackground))
        .draggable(task.id.uuidString)
        .contextMenu {
            Button("Сделать") { viewModel.setQuadrant(task, important: true, urgent: true) }
            Button("Запланировать") { viewModel.setQuadrant(task, important: true, urgent: false) }
            Button("Делегировать / сократить") { viewModel.setQuadrant(task, important: false, urgent: true) }
            Button("Удалить / ограничить") { viewModel.setQuadrant(task, important: false, urgent: false) }
            Divider()
            Button("Редактировать") { onEdit(task) }
            Button("Удалить задачу", role: .destructive) { viewModel.delete(task) }
        }
    }

    private var inboxSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("РАЗОБРАТЬ")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Palette.textSecondary)

            if inboxTasks.isEmpty {
                Text("Нет задач для сортировки")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.textSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(inboxTasks) { task in
                            matrixChip(task, important: nil, urgent: nil)
                                .frame(width: 130)
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.cardBackground))
        .dropDestination(for: String.self) { items, _ in
            return handleDrop(items, important: nil, urgent: nil)
        }
    }

    private func handleDrop(_ items: [String], important: Bool?, urgent: Bool?) -> Bool {
        guard
            let idString = items.first,
            let uuid = UUID(uuidString: idString),
            let task = viewModel.tasks.first(where: { $0.id == uuid })
        else { return false }
        viewModel.setQuadrant(task, important: important, urgent: urgent)
        return true
    }
}
