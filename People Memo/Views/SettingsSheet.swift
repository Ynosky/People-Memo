//
//  SettingsSheet.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isGenerating = false
    @State private var showSuccess = false
    @State private var showingDataAlert = false
    @State private var dataAlertMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section("データ") {
                    Button(action: {
                        generateDummyData()
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.brandPrimary)
                                .frame(width: 24)
                            
                            Text("ダミーデータを生成")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if isGenerating {
                                ProgressView()
                            } else if showSuccess {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .disabled(isGenerating)
                }
                
                Section("外観") {
                    HStack(spacing: 12) {
                        // ライトモードボタン
                        Button(action: {
                            isDarkMode = false
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        }) {
                            HStack {
                                Image(systemName: "sun.max.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(isDarkMode ? .secondary : .brandPrimary)
                                
                                Text("ライトモード")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(isDarkMode ? .secondary : .brandPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isDarkMode ? Color.clear : Color.brandPrimary.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isDarkMode ? Color.cardBorder(for: colorScheme) : Color.brandPrimary, lineWidth: isDarkMode ? 1 : 2)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // ダークモードボタン
                        Button(action: {
                            isDarkMode = true
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        }) {
                            HStack {
                                Image(systemName: "moon.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(isDarkMode ? .brandPrimary : .secondary)
                                
                                Text("ダークモード")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(isDarkMode ? .brandPrimary : .secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isDarkMode ? Color.brandPrimary.opacity(0.1) : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isDarkMode ? Color.brandPrimary : Color.cardBorder(for: colorScheme), lineWidth: isDarkMode ? 2 : 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Section("情報") {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .alert("データ生成", isPresented: $showingDataAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(dataAlertMessage)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func generateDummyData() {
        guard !isGenerating else { return }
        
        isGenerating = true
        showSuccess = false
        
        Task {
            DataSeeder.createSampleData(modelContext: modelContext)
            
            await MainActor.run {
                isGenerating = false
                showSuccess = true
                
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                dataAlertMessage = "ダミーデータの生成が完了しました。"
                showingDataAlert = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        showSuccess = false
                    }
                }
            }
        }
    }
}

