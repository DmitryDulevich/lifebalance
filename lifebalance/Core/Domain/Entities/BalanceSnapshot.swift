import Foundation
import SwiftData

@Model
final class BalanceSnapshot: Identifiable {
    var id: UUID
    var createdAt: Date
    var note: String?

    @Relationship(deleteRule: .cascade, inverse: \BalanceRating.snapshot)
    var ratings: [BalanceRating] = []

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        note: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.note = note
    }
}
