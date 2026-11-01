import Foundation
import Observation

@Observable
@MainActor
final class AnalyticsViewModel {
    var selectedPeriod: AnalyticsPeriod = .sevenDays
    var state: ViewState<AnalyticsReport> = .idle

    private let buildAnalyticsUseCase: BuildAnalyticsUseCase

    init(buildAnalyticsUseCase: BuildAnalyticsUseCase) {
        self.buildAnalyticsUseCase = buildAnalyticsUseCase
    }

    func load() {
        state = .loading
        do {
            state = .content(try buildAnalyticsUseCase.execute(period: selectedPeriod))
        } catch {
            AppLogger.error(error, context: "analytics.load")
            state = .error(error.localizedDescription)
        }
    }

    func selectPeriod(_ period: AnalyticsPeriod) {
        guard selectedPeriod != period else { return }
        selectedPeriod = period
        load()
    }
}
