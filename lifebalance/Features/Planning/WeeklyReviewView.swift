import SwiftUI

struct WeeklyReviewView: View {
    @State private var viewModel: WeeklyReviewViewModel

    init(container: AppContainer) {
        _viewModel = State(initialValue: container.makeWeeklyReviewViewModel())
    }

    var body: some View {
        ScrollView {
            if let report = viewModel.report {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Итоги недели")
                        .font(.title2.bold())

                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 10) {
                        StatTile(value: "\(report.completedTasks.count)", label: String(localized: "задач выполнено"))
                        StatTile(value: "\(report.focusMinutes)", label: String(localized: "минут фокуса"))
                        StatTile(
                            value: "\(report.habitCheckInCount)/\(report.habitTargetCount)",
                            label: String(localized: "привычки")
                        )
                        StatTile(
                            value: report.balanceAverage.map { String(format: "%.1f", $0) } ?? "—",
                            label: String(localized: "средний баланс")
                        )
                    }

                    if !report.unfinishedTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Перенести на следующую неделю").font(.headline)
                            ForEach(report.unfinishedTasks) { task in
                                Button { viewModel.toggleSelection(task) } label: {
                                    HStack {
                                        Image(systemName: viewModel.selectedTaskIDs.contains(task.id)
                                              ? "checkmark.circle.fill" : "circle")
                                        Text(task.title)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Palette.cardBackground))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Что получилось").font(.headline)
                        TextField("Короткий итог недели", text: $viewModel.note, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                        Text("Главные приоритеты").font(.headline)
                        TextField("До трёх приоритетов следующей недели", text: $viewModel.priorities, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button(viewModel.didSave ? "Обновить обзор" : "Завершить обзор") {
                        viewModel.completeReview()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(20)
            } else {
                ProgressView().padding(.top, 80)
            }
        }
        .background(ScreenBackground())
        .navigationTitle("Обзор недели")
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.load() }
        .appErrorAlert($viewModel.errorMessage)
    }
}
