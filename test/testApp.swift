//
//  testApp.swift
//  test
//
//  Created by DDS on 06.03.2026.
//

import SwiftUI
import SwiftData

@main
struct testApp: App {
    let modelContainer: ModelContainer = {
        let schema = Schema([
            UserSettings.self,
            LifeArea.self,
            BalanceSnapshot.self,
            BalanceRating.self,
            TaskItem.self,
            Goal.self,
            FocusSession.self
        ])
        do {
            return try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
