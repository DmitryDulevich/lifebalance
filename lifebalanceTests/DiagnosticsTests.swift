import Foundation
import Testing
@testable import lifebalance

@Suite("Diagnostics")
struct DiagnosticsTests {
    @Test
    func keepsBoundedPrivacySafeBreadcrumbs() throws {
        let suiteName = "DiagnosticsTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let diagnostics = AppDiagnostics(
            defaults: defaults,
            maximumEventCount: 2
        )
        let privateText = "Секретное название задачи"

        diagnostics.record(level: .info, context: "first")
        diagnostics.record(
            level: .error,
            context: "storage.save",
            error: NSError(
                domain: "TestDomain",
                code: 42,
                userInfo: [NSLocalizedDescriptionKey: privateText]
            )
        )
        diagnostics.record(level: .notice, context: "last")

        let events = diagnostics.events()
        #expect(events.map(\.context) == ["storage.save", "last"])
        #expect(events.first?.errorDomain == "TestDomain")
        #expect(events.first?.errorCode == 42)
        #expect(!diagnostics.makeReport().contains(privateText))
    }

    @Test
    func classifiesStorageFailures() {
        let diskError = NSError(
            domain: NSCocoaErrorDomain,
            code: CocoaError.fileWriteOutOfSpace.rawValue
        )
        let migrationError = NSError(domain: NSCocoaErrorDomain, code: 134_110)
        let wrappedError = NSError(
            domain: "Wrapper",
            code: 1,
            userInfo: [NSUnderlyingErrorKey: migrationError]
        )

        #expect(StorageDiagnostics.category(for: diskError) == .diskFull)
        #expect(StorageDiagnostics.category(for: wrappedError) == .migration)
        #expect(
            StorageDiagnostics.category(
                for: NSError(domain: "Unknown", code: -1)
            ) == .unknown
        )
    }
}
