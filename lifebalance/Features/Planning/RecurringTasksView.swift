import SwiftUI

struct RecurringTasksView: View {
    let repository: RecurringTaskRepository
    @State private var templates: [RecurringTask] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            if templates.isEmpty {
                ContentUnavailableView(
                    "Нет повторяющихся задач",
                    systemImage: "calendar.badge.clock",
                    description: Text("Повторение можно включить при создании задачи.")
                )
            } else {
                ForEach(templates) { template in
                    HStack(spacing: 12) {
                        Image(systemName: template.isActive ? "repeat.circle.fill" : "pause.circle")
                            .font(.title2)
                            .foregroundStyle(template.isActive ? Palette.accent : Palette.textSecondary)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(template.title).font(.headline)
                            Text(template.frequency.localizedTitle)
                                .font(.caption)
                                .foregroundStyle(Palette.textSecondary)
                            Text("Следующее выполнение: \(template.nextDueDate.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption2)
                                .foregroundStyle(Palette.textSecondary)
                        }
                        Spacer()
                        Menu {
                            Button(template.isActive ? "Поставить на паузу" : "Возобновить") {
                                toggle(template)
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Повторяющиеся задачи")
        .task { load() }
        .appErrorAlert($errorMessage)
    }

    private func load() {
        do {
            templates = try repository.fetchAll()
            errorMessage = nil
        } catch {
            AppLogger.error(error, context: "recurring_tasks.load")
            errorMessage = error.localizedDescription
        }
    }

    private func toggle(_ template: RecurringTask) {
        let previous = template.isActive
        template.isActive.toggle()
        do {
            try repository.save()
            load()
        } catch {
            template.isActive = previous
            AppLogger.error(error, context: "recurring_tasks.status")
            errorMessage = error.localizedDescription
        }
    }
}
