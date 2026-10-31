import SwiftUI
import SwiftData

struct RootView: View {
    private enum StartupState {
        case loading
        case ready
        case failed(String)
    }

    @Environment(\.modelContext) private var modelContext
    @State private var container: AppContainer?
    @State private var settings: UserSettings?
    @State private var startupState: StartupState = .loading
    private let persistenceErrorMessage: String?

    init(persistenceErrorMessage: String? = nil) {
        self.persistenceErrorMessage = persistenceErrorMessage
    }

    var body: some View {
        Group {
            switch startupState {
            case .loading:
                ProgressView()

            case .ready:
                readyContent

            case .failed(let message):
                startupErrorView(
                    message: message,
                    canRetry: persistenceErrorMessage == nil
                )
            }
        }
        .task {
            initialize()
        }
    }

    @ViewBuilder
    private var readyContent: some View {
        if let container, let settings {
            if settings.onboardingStep == .completed {
                MainTabView(container: container)
            } else {
                OnboardingCoordinatorView(
                    container: container,
                    startingAt: settings.onboardingStep
                )
            }
        } else {
            startupErrorView(
                message: "Приложение запущено без необходимых настроек.",
                canRetry: true
            )
        }
    }

    private func startupErrorView(message: String, canRetry: Bool) -> some View {
        ContentUnavailableView {
            Label("Не удалось запустить приложение", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            if canRetry {
                Button("Повторить") {
                    initialize()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func initialize() {
        startupState = .loading

        if let persistenceErrorMessage {
            startupState = .failed(persistenceErrorMessage)
            return
        }

        let appContainer = container ?? AppContainer(modelContext: modelContext)
        container = appContainer

        do {
            settings = try appContainer.userSettingsRepository.fetchOrCreate()
            startupState = .ready
        } catch {
            AppLogger.error(error, context: "startup.initialize")
            startupState = .failed(error.localizedDescription)
        }
    }
}
