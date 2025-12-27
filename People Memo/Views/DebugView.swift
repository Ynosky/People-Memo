//
//  DebugView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData

struct DebugView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // ダミーデータ生成ボタン
                Button(action: {
                    generateDummyData()
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "database.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                        
                        Text("ダミーデータを生成")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Generate Data")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 40)
                
                Text("開発・デバッグ用のサンプルデータを生成します")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Debug")
            .alert("生成完了", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func generateDummyData() {
        DataSeeder.createSampleData(modelContext: modelContext)
        alertMessage = "ダミーデータの生成が完了しました。\n人物、会話、ハイライトが追加されました。"
        showingAlert = true
    }
}

#Preview {
    DebugView()
        .modelContainer(for: [Person.self, Meeting.self, Note.self, TranscriptBlock.self, AgendaItem.self], inMemory: true)
}

