import Foundation
import OSLog

enum AppLogger {
    private static let errors = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "lifebalance",
        category: "errors"
    )

    static func error(_ error: Error, context: String) {
        errors.error(
            "\(context, privacy: .public): \(error.localizedDescription, privacy: .private(mask: .hash))"
        )
    }
}
