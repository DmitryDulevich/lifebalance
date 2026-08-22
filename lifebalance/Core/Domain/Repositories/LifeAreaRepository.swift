import Foundation

@MainActor
protocol LifeAreaRepository {
    func fetchActiveAreas() throws -> [LifeArea]
    func insert(_ areas: [LifeArea]) throws
}
