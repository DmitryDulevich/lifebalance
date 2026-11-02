import Foundation

enum StorageFailureCategory: String, Sendable {
    case diskFull = "disk_full"
    case permission = "permission"
    case migration = "migration"
    case corruptedStore = "corrupted_store"
    case unknown
}

enum StorageDiagnostics {
    static func category(for error: Error) -> StorageFailureCategory {
        for item in errorChain(error) {
            if item.domain == NSCocoaErrorDomain {
                if item.code == CocoaError.fileWriteOutOfSpace.rawValue {
                    return .diskFull
                }
                if item.code == CocoaError.fileReadNoPermission.rawValue
                    || item.code == CocoaError.fileWriteNoPermission.rawValue {
                    return .permission
                }
                if (134_100...134_190).contains(item.code) {
                    return .migration
                }
                if item.code == 134_030 || item.code == 134_080 {
                    return .corruptedStore
                }
            }
        }
        return .unknown
    }

    static func markReady() {
        AppDiagnostics.shared.updateStorageHealth(
            StorageHealth(
                state: .ready,
                checkedAt: .now,
                schemaVersion: "4.0.0",
                failureCategory: nil
            )
        )
    }

    static func markFallback(after error: Error) {
        AppDiagnostics.shared.updateStorageHealth(
            StorageHealth(
                state: .fallback,
                checkedAt: .now,
                schemaVersion: "4.0.0",
                failureCategory: category(for: error).rawValue
            )
        )
    }

    static func markFailed(after error: Error) {
        AppDiagnostics.shared.updateStorageHealth(
            StorageHealth(
                state: .failed,
                checkedAt: .now,
                schemaVersion: "4.0.0",
                failureCategory: category(for: error).rawValue
            )
        )
    }

    private static func errorChain(_ error: Error) -> [NSError] {
        var result: [NSError] = []
        var current: NSError? = error as NSError
        while let item = current, result.count < 8 {
            result.append(item)
            current = item.userInfo[NSUnderlyingErrorKey] as? NSError
        }
        return result
    }
}
