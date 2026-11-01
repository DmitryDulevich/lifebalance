import SwiftUI

struct DiagnosticsView: View {
    @State private var events: [DiagnosticEvent] = []
    @State private var storageHealth: StorageHealth = .unknown
    @State private var reportURL: URL?
    @State private var errorMessage: String?
    @State private var isShowingClearConfirmation = false

    var body: some View {
        List {
            Section("Хранилище") {
                LabeledContent("Состояние", value: storageTitle)
                    .accessibilityIdentifier("diagnostics.storage.state")
                LabeledContent("Схема", value: storageHealth.schemaVersion)
                LabeledContent(
                    "Последняя проверка",
                    value: storageHealth.checkedAt.formatted(date: .abbreviated, time: .shortened)
                )
                if let category = storageHealth.failureCategory {
                    LabeledContent("Категория ошибки", value: category)
                }
            }

            Section {
                if let reportURL {
                    ShareLink(item: reportURL) {
                        Label("Экспортировать отчёт", systemImage: "square.and.arrow.up")
                    }
                    .accessibilityIdentifier("diagnostics.export")
                } else {
                    Button("Подготовить отчёт") {
                        prepareReport()
                    }
                }

                Button("Очистить диагностику", role: .destructive) {
                    isShowingClearConfirmation = true
                }
            } footer: {
                Text("Отчёт содержит технические коды и контексты операций. Названия задач, целей и другие пользовательские данные не собираются.")
            }

            Section("Последние события") {
                if events.isEmpty {
                    Text("Диагностических событий пока нет")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(events.reversed()) { event in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(event.context)
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text(event.level.rawValue.uppercased())
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(color(for: event.level))
                            }
                            Text(event.timestamp.formatted(date: .abbreviated, time: .standard))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let domain = event.errorDomain {
                                Text("\(domain) #\(event.errorCode ?? 0) · \(event.id.uuidString.prefix(8))")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .textSelection(.enabled)
                    }
                }
            }
        }
        .navigationTitle("Диагностика")
        .onAppear(perform: refresh)
        .confirmationDialog(
            "Очистить диагностические события?",
            isPresented: $isShowingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Очистить", role: .destructive) {
                AppDiagnostics.shared.clear()
                refresh()
            }
            Button("Отмена", role: .cancel) {}
        }
        .appErrorAlert($errorMessage, title: "Не удалось подготовить отчёт")
    }

    private var storageTitle: String {
        switch storageHealth.state {
        case .unknown: "Не проверено"
        case .ready: "Работает"
        case .fallback: "Резервный режим"
        case .failed: "Ошибка"
        }
    }

    private func refresh() {
        events = AppDiagnostics.shared.events()
        storageHealth = AppDiagnostics.shared.storageHealth()
        reportURL = nil
        prepareReport()
    }

    private func prepareReport() {
        do {
            reportURL = try AppDiagnostics.shared.makeReportFile()
        } catch {
            AppLogger.error(error, context: "diagnostics.report.create")
            errorMessage = error.localizedDescription
        }
    }

    private func color(for level: DiagnosticLevel) -> Color {
        switch level {
        case .info: .secondary
        case .notice: .orange
        case .error, .critical: .red
        }
    }
}
