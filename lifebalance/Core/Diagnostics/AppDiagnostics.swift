import Foundation

enum DiagnosticLevel: String, Codable, Sendable {
    case info
    case notice
    case error
    case critical
}

struct DiagnosticEvent: Identifiable, Codable, Sendable {
    let id: UUID
    let timestamp: Date
    let level: DiagnosticLevel
    let context: String
    let errorDomain: String?
    let errorCode: Int?
    let underlyingErrors: [String]
    let metadata: [String: String]
}

struct StorageHealth: Codable, Sendable {
    enum State: String, Codable, Sendable {
        case unknown
        case ready
        case fallback
        case failed
    }

    var state: State
    var checkedAt: Date
    var schemaVersion: String
    var failureCategory: String?

    static let unknown = StorageHealth(
        state: .unknown,
        checkedAt: .now,
        schemaVersion: "3.0.0",
        failureCategory: nil
    )
}

/// A small, privacy-safe breadcrumb buffer that survives process termination.
/// It deliberately stores error domains/codes, but never user-entered text or paths.
final class AppDiagnostics: @unchecked Sendable {
    static let shared = AppDiagnostics()

    private enum Keys {
        static let events = "diagnostics.events.v1"
        static let storage = "diagnostics.storage.v1"
    }

    private let lock = NSLock()
    private let defaults: UserDefaults
    private let fileManager: FileManager
    private let maximumEventCount: Int

    init(
        defaults: UserDefaults = .standard,
        fileManager: FileManager = .default,
        maximumEventCount: Int = 100
    ) {
        self.defaults = defaults
        self.fileManager = fileManager
        self.maximumEventCount = maximumEventCount
    }

    @discardableResult
    func record(
        level: DiagnosticLevel,
        context: String,
        error: Error? = nil,
        metadata: [String: String] = [:]
    ) -> UUID {
        let nsError = error as NSError?
        let event = DiagnosticEvent(
            id: UUID(),
            timestamp: .now,
            level: level,
            context: context,
            errorDomain: nsError?.domain,
            errorCode: nsError?.code,
            underlyingErrors: Self.underlyingErrorSignatures(from: nsError),
            metadata: metadata
        )

        lock.withLock {
            var current = loadEventsUnlocked()
            current.append(event)
            if current.count > maximumEventCount {
                current.removeFirst(current.count - maximumEventCount)
            }
            if let data = try? JSONEncoder().encode(current) {
                defaults.set(data, forKey: Keys.events)
            }
        }
        return event.id
    }

    func events() -> [DiagnosticEvent] {
        lock.withLock { loadEventsUnlocked() }
    }

    func updateStorageHealth(_ health: StorageHealth) {
        lock.withLock {
            if let data = try? JSONEncoder().encode(health) {
                defaults.set(data, forKey: Keys.storage)
            }
        }
    }

    func storageHealth() -> StorageHealth {
        lock.withLock {
            guard
                let data = defaults.data(forKey: Keys.storage),
                let health = try? JSONDecoder().decode(StorageHealth.self, from: data)
            else {
                return .unknown
            }
            return health
        }
    }

    func storeMetricKitPayload(_ data: Data) {
        do {
            let directory = try diagnosticsDirectory()
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let timestamp = Int64(Date.now.timeIntervalSince1970 * 1_000)
            let name = "metric-\(String(format: "%013lld", timestamp))-\(UUID().uuidString).json"
            try data.write(to: directory.appending(path: name), options: .atomic)
            try pruneMetricPayloads(in: directory, keeping: 3)
            record(
                level: .critical,
                context: "crash.metric_kit.received",
                metadata: ["bytes": String(data.count)]
            )
        } catch {
            record(level: .error, context: "crash.metric_kit.persist", error: error)
        }
    }

    func makeReport() -> String {
        let events = events()
        let storage = storageHealth()
        var lines = [
            "LifeBalance diagnostics",
            "Generated: \(Self.iso8601(.now))",
            "App version: \(Self.appVersion)",
            "Build: \(Self.buildVersion)",
            "OS: \(ProcessInfo.processInfo.operatingSystemVersionString)",
            "Schema: \(storage.schemaVersion)",
            "Storage: \(storage.state.rawValue)",
            "Storage check: \(Self.iso8601(storage.checkedAt))",
            "Storage failure category: \(storage.failureCategory ?? "none")",
            "",
            "Breadcrumbs (user content is not collected):"
        ]

        for event in events {
            let error = event.errorDomain.map { domain in
                " error=\(domain)#\(event.errorCode ?? 0)"
            } ?? ""
            let metadata = event.metadata.isEmpty
                ? ""
                : " metadata=" + event.metadata
                    .sorted { $0.key < $1.key }
                    .map { "\($0.key)=\($0.value)" }
                    .joined(separator: ",")
            lines.append(
                "\(Self.iso8601(event.timestamp)) [\(event.level.rawValue)] "
                    + "\(event.context) id=\(event.id.uuidString.prefix(8))\(error)\(metadata)"
            )
            for underlying in event.underlyingErrors {
                lines.append("  underlying=\(underlying)")
            }
        }

        if let directory = try? diagnosticsDirectory(),
           let payloads = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles]
           ) {
            lines.append("")
            lines.append("MetricKit payloads: \(payloads.count)")
            for url in payloads.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                lines.append("  \(url.lastPathComponent) (\(size) bytes)")
                if let data = try? Data(contentsOf: url),
                   let json = String(data: data, encoding: .utf8) {
                    lines.append("--- BEGIN \(url.lastPathComponent) ---")
                    lines.append(json)
                    lines.append("--- END \(url.lastPathComponent) ---")
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    func makeReportFile() throws -> URL {
        let url = fileManager.temporaryDirectory.appending(path: "lifebalance-diagnostics.txt")
        try Data(makeReport().utf8).write(to: url, options: .atomic)
        return url
    }

    func clear() {
        lock.withLock {
            defaults.removeObject(forKey: Keys.events)
            defaults.removeObject(forKey: Keys.storage)
        }
        if let directory = try? diagnosticsDirectory() {
            try? fileManager.removeItem(at: directory)
        }
    }

    private func loadEventsUnlocked() -> [DiagnosticEvent] {
        guard
            let data = defaults.data(forKey: Keys.events),
            let events = try? JSONDecoder().decode([DiagnosticEvent].self, from: data)
        else {
            return []
        }
        return events
    }

    private func diagnosticsDirectory() throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appending(path: "Diagnostics", directoryHint: .isDirectory)
    }

    private func pruneMetricPayloads(in directory: URL, keeping limit: Int) throws {
        let urls = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        let sorted = urls.sorted { $0.lastPathComponent > $1.lastPathComponent }
        for url in sorted.dropFirst(limit) {
            try fileManager.removeItem(at: url)
        }
    }

    private static func underlyingErrorSignatures(from error: NSError?) -> [String] {
        var signatures: [String] = []
        var current = error?.userInfo[NSUnderlyingErrorKey] as? NSError
        while let error = current, signatures.count < 5 {
            signatures.append("\(error.domain)#\(error.code)")
            current = error.userInfo[NSUnderlyingErrorKey] as? NSError
        }
        return signatures
    }

    private static func iso8601(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }

    private static var buildVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
    }
}

private extension NSLock {
    func withLock<T>(_ operation: () -> T) -> T {
        lock()
        defer { unlock() }
        return operation()
    }
}
