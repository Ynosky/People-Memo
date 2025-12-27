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
        
        // マイグレーション設定：スキーマ変更を自動的に処理
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // エラーが発生した場合、データベースをリセットして再作成
            print("⚠️ ModelContainer creation failed: \(error)")
            print("🔄 Attempting to reset database...")
            
            // 既存のデータベースファイルを削除して再作成
            do {
                // デフォルトのデータベースファイルの場所を取得
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let defaultStoreURL = documentsPath.appendingPathComponent("default.store")
                
                if FileManager.default.fileExists(atPath: defaultStoreURL.path) {
                    try FileManager.default.removeItem(at: defaultStoreURL)
                    print("✅ Database file removed: \(defaultStoreURL.path)")
                }
                
                // 新しいコンテナを作成
                let newConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    allowsSave: true
                )
                return try ModelContainer(for: schema, configurations: [newConfiguration])
            } catch {
                fatalError("Could not create ModelContainer even after reset: \(error)")
            }
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
