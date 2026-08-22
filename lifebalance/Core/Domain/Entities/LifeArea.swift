import Foundation
import SwiftData

@Model
final class LifeArea: Identifiable {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var order: Int
    var isActive: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        order: Int,
        isActive: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.order = order
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
