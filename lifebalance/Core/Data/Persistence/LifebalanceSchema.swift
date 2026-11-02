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

/// Preserves historical meaning when tasks, goals, or life areas change later.
/// Unchanged models intentionally reuse their V2 definitions.
enum LifebalanceSchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            LifebalanceSchemaV2.UserSettings.self,
            LifebalanceSchemaV2.LifeArea.self,
            LifebalanceSchemaV2.BalanceSnapshot.self,
            LifebalanceSchemaV2.BalanceRating.self,
            LifebalanceSchemaV2.TaskItem.self,
            LifebalanceSchemaV2.Goal.self,
            GoalStatusEvent.self,
            FocusSession.self
        ]
    }
}

/// Adds planning features without changing the existing task graph.
/// Recurrence templates generate independent task instances, so completed
/// occurrences remain available to history and analytics.
enum LifebalanceSchemaV4: VersionedSchema {
    static let versionIdentifier = Schema.Version(4, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            LifebalanceSchemaV2.UserSettings.self,
            LifebalanceSchemaV2.LifeArea.self,
            LifebalanceSchemaV2.BalanceSnapshot.self,
            LifebalanceSchemaV2.BalanceRating.self,
            LifebalanceSchemaV2.TaskItem.self,
            LifebalanceSchemaV2.Goal.self,
            LifebalanceSchemaV3.GoalStatusEvent.self,
            LifebalanceSchemaV3.FocusSession.self,
            RecurringTask.self,
            Habit.self,
            HabitCheckIn.self,
            WeeklyReview.self
        ]
    }
}

enum LifebalanceMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            LifebalanceSchemaV1.self,
            LifebalanceSchemaV2.self,
            LifebalanceSchemaV3.self,
            LifebalanceSchemaV4.self
        ]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(
                fromVersion: LifebalanceSchemaV1.self,
                toVersion: LifebalanceSchemaV2.self
            ),
            .lightweight(
                fromVersion: LifebalanceSchemaV2.self,
                toVersion: LifebalanceSchemaV3.self
            ),
            .lightweight(
                fromVersion: LifebalanceSchemaV3.self,
                toVersion: LifebalanceSchemaV4.self
            )
        ]
    }
}
