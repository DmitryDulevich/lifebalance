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
    private let persistence = AppPersistence.bootstrap()

    var body: some Scene {
        WindowGroup {
            RootView(persistenceErrorMessage: persistence.startupErrorMessage)
        }
        .modelContainer(persistence.modelContainer)
    }
}
