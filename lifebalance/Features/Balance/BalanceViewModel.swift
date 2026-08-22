import Foundation
import Observation

@Observable
@MainActor
final class BalanceViewModel {
    struct AreaRow: Identifiable {
        let area: LifeArea
        var value: Int
        var id: UUID { area.id }
    }

    var rows: [AreaRow] = []
    var errorMessage: String?

    private let lifeAreaRepository: LifeAreaRepository
    private let balanceRepository: BalanceRepository
    private let adjustBalanceRatingUseCase: AdjustBalanceRatingUseCase

    init(container: AppContainer) {
        self.lifeAreaRepository = container.lifeAreaRepository
        self.balanceRepository = container.balanceRepository
        self.adjustBalanceRatingUseCase = container.adjustBalanceRatingUseCase
    }

    var averageScore: Double {
        let ratedRows = rows.filter { $0.value > 0 }
        guard !ratedRows.isEmpty else { return 0 }
        return Double(ratedRows.reduce(0) { $0 + $1.value }) / Double(ratedRows.count)
    }

    /// (sphere color hex, rating or nil if unrated) per area, in display order.
    var radarAxes: [(colorHex: String, value: Int?)] {
        rows.map { ($0.area.colorHex, $0.value == 0 ? nil : $0.value) }
    }

    func load() {
        do {
            let areas = try lifeAreaRepository.fetchActiveAreas()
            let latestSnapshot = try balanceRepository.fetchLatestSnapshot()
            let ratingsByAreaID: [UUID: Int] = Dictionary(
                uniqueKeysWithValues: (latestSnapshot?.ratings ?? []).compactMap { rating -> (UUID, Int)? in
                    guard let areaID = rating.area?.id, let value = rating.value else { return nil }
                    return (areaID, value)
                }
            )
            rows = areas.map { area in
                AreaRow(area: area, value: ratingsByAreaID[area.id] ?? 0)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func adjust(_ row: AreaRow, delta: Int) {
        guard let index = rows.firstIndex(where: { $0.id == row.id }) else { return }
        let current = rows[index].value
        if current == 0 {
            guard delta > 0 else { return }
            rows[index].value = 1
        } else {
            rows[index].value = min(10, max(1, current + delta))
        }
        persist()
    }

    private func persist() {
        let inputs = rows.map { row in
            AreaRatingInput(area: row.area, value: row.value == 0 ? nil : row.value, note: nil)
        }
        do {
            try adjustBalanceRatingUseCase.execute(ratings: inputs)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
