import SwiftData

/// The first explicitly versioned snapshot of the app's persistent data model.
///
/// Keep this list stable. Future model changes must be introduced through a new
/// `VersionedSchema` and a stage in `LifebalanceMigrationPlan`.
enum LifebalanceSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            UserSettings.self,
            LifeArea.self,
            BalanceSnapshot.self,
            BalanceRating.self,
            TaskItem.self,
            Goal.self,
            FocusSession.self
        ]
    }
}

/// Adds database-level uniqueness for every entity identifier.
enum LifebalanceSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            UserSettings.self,
            LifeArea.self,
            BalanceSnapshot.self,
            BalanceRating.self,
            TaskItem.self,
            Goal.self,
            FocusSession.self
        ]
    }
}

enum LifebalanceMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            LifebalanceSchemaV1.self,
            LifebalanceSchemaV2.self
        ]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(
                fromVersion: LifebalanceSchemaV1.self,
                toVersion: LifebalanceSchemaV2.self
            )
        ]
    }
}
