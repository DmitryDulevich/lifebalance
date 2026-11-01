import Foundation
import OSLog

enum AppLogger {
    private static let lifecycle = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "lifebalance",
        category: "lifecycle"
    )
    private static let errors = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "lifebalance",
        category: "errors"
    )

    static func info(_ context: String, metadata: [String: String] = [:]) {
        lifecycle.info("\(context, privacy: .public)")
        AppDiagnostics.shared.record(level: .info, context: context, metadata: metadata)
    }

    static func notice(_ context: String, metadata: [String: String] = [:]) {
        lifecycle.notice("\(context, privacy: .public)")
        AppDiagnostics.shared.record(level: .notice, context: context, metadata: metadata)
    }

    @discardableResult
    static func error(_ error: Error, context: String) -> UUID {
        errors.error(
            "\(context, privacy: .public): \(error.localizedDescription, privacy: .private(mask: .hash))"
        )
        return AppDiagnostics.shared.record(level: .error, context: context, error: error)
    }

    @discardableResult
    static func critical(_ error: Error, context: String) -> UUID {
        errors.critical(
            "\(context, privacy: .public): \(error.localizedDescription, privacy: .private(mask: .hash))"
        )
        return AppDiagnostics.shared.record(level: .critical, context: context, error: error)
    }
}
