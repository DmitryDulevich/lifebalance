import Foundation
import SwiftData

extension LifebalanceSchemaV1 {
    @Model
    final class BalanceRating: Identifiable {
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
}

extension LifebalanceSchemaV2 {
    @Model
    final class BalanceRating: Identifiable {
        @Attribute(.unique) var id: UUID
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
}

typealias BalanceRating = LifebalanceSchemaV2.BalanceRating
