//
//  lifebalanceApp.swift
//  lifebalance
//
//  Created by DDS on 06.03.2026.
//

import SwiftUI
import SwiftData

@main
struct LifebalanceApp: App {
    private let persistence: AppPersistence?

    init() {
        if Self.isUnitTestHost {
            persistence = nil
        } else {
            MetricKitCrashReporter.shared.start()
            AppLogger.info("app.launch")
            persistence = AppPersistence.bootstrap()
        }
    }

    var body: some Scene {
        WindowGroup {
            if let persistence {
                RootView(persistenceErrorMessage: persistence.startupErrorMessage)
                    .modelContainer(persistence.modelContainer)
            } else {
                EmptyView()
            }
        }
    }

    private static var isUnitTestHost: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            && !ProcessInfo.processInfo.arguments.contains("--ui-testing")
    }
}
