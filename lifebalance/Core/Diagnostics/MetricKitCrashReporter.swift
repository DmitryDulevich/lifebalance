import Foundation
import MetricKit

/// MetricKit delivers crash and hang diagnostics on a later app launch.
/// Payloads remain on-device until the user explicitly exports diagnostics.
final class MetricKitCrashReporter: NSObject, MXMetricManagerSubscriber, @unchecked Sendable {
    static let shared = MetricKitCrashReporter()

    func start() {
        MXMetricManager.shared.add(self)
    }

    nonisolated func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            let data = payload.jsonRepresentation()
            Task { @MainActor in
                AppDiagnostics.shared.storeMetricKitPayload(data)
            }
        }
    }
}
