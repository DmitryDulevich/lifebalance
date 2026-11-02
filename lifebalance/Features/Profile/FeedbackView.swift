import StoreKit
import SwiftUI

private enum FeedbackKind: String, CaseIterable, Identifiable {
    case suggestion
    case problem
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .suggestion: String(localized: "Предложение")
        case .problem: String(localized: "Проблема")
        case .other: String(localized: "Другое")
        }
    }
}

struct FeedbackView: View {
    @Environment(\.requestReview) private var requestReview
    @State private var kind: FeedbackKind = .suggestion
    @State private var message = ""
    @State private var includeDiagnostics = true
    @State private var reportURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                Picker("Тип обращения", selection: $kind) {
                    ForEach(FeedbackKind.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }

                TextEditor(text: $message)
                    .frame(minHeight: 130)
                    .overlay(alignment: .topLeading) {
                        if message.isEmpty {
                            Text("Расскажите, что можно улучшить")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }

                if kind == .problem {
                    Toggle("Приложить диагностику", isOn: $includeDiagnostics)
                }

                Button("Подготовить сообщение") {
                    prepareReport()
                }

                if let reportURL {
                    ShareLink(item: reportURL) {
                        Label("Отправить", systemImage: "square.and.arrow.up")
                    }
                    .accessibilityIdentifier("feedback.share")
                }
            } header: {
                Text("Сообщение разработчику")
            } footer: {
                Text("После подготовки выберите удобное приложение для отправки. Диагностика добавляется только по вашему выбору.")
            }

            Section {
                Button {
                    requestReview()
                } label: {
                    Label("Оценить в App Store", systemImage: "star.bubble")
                }
            } header: {
                Text("Поддержать приложение")
            } footer: {
                Text("iOS самостоятельно решает, когда показать окно оценки.")
            }
        }
        .navigationTitle("Обратная связь")
        .onChange(of: kind) { _, _ in reportURL = nil }
        .onChange(of: message) { _, _ in reportURL = nil }
        .onChange(of: includeDiagnostics) { _, _ in reportURL = nil }
        .appErrorAlert($errorMessage, title: String(localized: "Не удалось подготовить сообщение"))
    }

    private func prepareReport() {
        do {
            let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
            var content = """
            Balance feedback
            Type: \(kind.rawValue)
            App version: \(appVersion)
            OS: \(ProcessInfo.processInfo.operatingSystemVersionString)

            Message:
            \(message.trimmingCharacters(in: .whitespacesAndNewlines))
            """
            if kind == .problem && includeDiagnostics {
                content += "\n\n--- Diagnostics ---\n" + AppDiagnostics.shared.makeReport()
            }
            let url = FileManager.default.temporaryDirectory
                .appending(path: "balance-feedback.txt")
            try Data(content.utf8).write(to: url, options: .atomic)
            reportURL = url
            errorMessage = nil
        } catch {
            AppLogger.error(error, context: "feedback.report.create")
            errorMessage = error.localizedDescription
        }
    }
}
