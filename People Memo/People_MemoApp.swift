//
//  People_MemoApp.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData

@main
struct People_MemoApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Person.self,
            Meeting.self,
            Note.self,
            TranscriptBlock.self,
            AgendaItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .modelContainer(sharedModelContainer)
    }
}
