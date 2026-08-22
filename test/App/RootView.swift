import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [UserSettings]
    @State private var container: AppContainer?

    var body: some View {
        Group {
            if let container, let settings = settingsList.first {
                if settings.onboardingStep == .completed {
                    MainTabView(container: container)
                } else {
                    OnboardingCoordinatorView(container: container, startingAt: settings.onboardingStep)
                }
            } else {
                ProgressView()
            }
        }
        .task {
            guard container == nil else { return }
            let newContainer = AppContainer(modelContext: modelContext)
            container = newContainer
            _ = try? newContainer.userSettingsRepository.fetchOrCreate()
        }
    }
}
