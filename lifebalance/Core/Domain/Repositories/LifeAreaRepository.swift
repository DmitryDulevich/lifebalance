import Foundation

@MainActor
protocol LifeAreaRepository {
    func fetchActiveAreas() throws -> [LifeArea]
    func fetchAllAreas() throws -> [LifeArea]
    func insert(_ areas: [LifeArea]) throws
    func save() throws
}
