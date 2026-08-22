import Foundation
import SwiftData

@Model
final class BalanceRating {
    var id: UUID
    var value: Int?
    var note: String?
    var area: LifeArea?
    var snapshot: BalanceSnapshot?

    init(
        id: UUID = UUID(),
        value: Int? = nil,
        note: String? = nil,
        area: LifeArea? = nil,
        snapshot: BalanceSnapshot? = nil
    ) {
        self.id = id
        self.value = value
        self.note = note
        self.area = area
        self.snapshot = snapshot
    }
}
