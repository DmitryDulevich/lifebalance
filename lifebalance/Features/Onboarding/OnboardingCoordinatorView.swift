import SwiftUI

struct OnboardingCoordinatorView: View {
    let container: AppContainer
    @State private var currentStep: OnboardingStep

    init(container: AppContainer, startingAt step: OnboardingStep) {
        self.container = container
        _currentStep = State(initialValue: step)
    }

    var body: some View {
        ZStack {
            ScreenBackground()

            switch currentStep {
            case .welcome:
                WelcomeView(container: container) {
                    currentStep = .areaSelection
                }
            case .areaSelection:
                AreaSelectionView(container: container) {
                    currentStep = .initialBalance
                }
            case .initialBalance:
                InitialBalanceView(container: container) {
                    currentStep = .completed
                }
            case .completed:
                Color.clear
            }
        }
        .animation(.easeInOut(duration: 0.2), value: currentStep)
    }
}
