//
//  HomeView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData
import UIKit

struct HomeView: View {
    @Query(sort: \Note.createdAt, order: .reverse) private var allNotes: [Note]
    @Query(sort: \Person.createdAt, order: .reverse) private var people: [Person]
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddModal = false
    @State private var isGenerating = false
    @State private var showSuccess = false
    @State private var selectedTag: String? = nil
    
    // フィルタリングされたメモ（最新20件）
    private var recentNotes: [Note] {
        let filtered: [Note]
        if let tag = selectedTag {
            // 選択されたタグを持つ人物のメモのみ
            filtered = allNotes.filter { note in
                guard let person = note.meeting?.person else { return false }
                return person.tags.contains(tag)
            }
        } else {
            filtered = allNotes
        }
        return Array(filtered.prefix(20))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // タグフィルターバー
                TagFilterBar(selectedTag: $selectedTag)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Quick Capture Section
                        VStack(spacing: 16) {
                        Button(action: {
                            showingAddModal = true
                        }) {
                            HStack {
                                Text("誰と会いましたか？")
                                    .font(.system(size: 20, weight: .medium, design: .rounded))
                                    .foregroundColor(Color.primaryText(for: colorScheme))
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24, weight: .medium, design: .rounded))
                                    .foregroundColor(.brandPrimary)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.cardBackground(for: colorScheme))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.cardBorder(for: colorScheme), lineWidth: 1)
                                    )
                                    .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                    
                    // Recent Memos Timeline
                    if !recentNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            // Section Header
                            HStack {
                                Text("最近のメモ")
                                    .font(.system(size: 24, weight: .bold, design: .serif))
                                    .foregroundColor(Color.primaryText(for: colorScheme))
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                            
                            // Timeline List
                            LazyVStack(spacing: 0) {
                                ForEach(recentNotes) { note in
                                    MemoCard(note: note)
                                        .padding(.horizontal, 20)
                                    
                                    if note.id != recentNotes.last?.id {
                                        Divider()
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 8)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 100) // FAB + TabBarのスペース
                    } else {
                        // Empty State
                        VStack(spacing: 16) {
                            Text("📝")
                                .font(.system(size: 64))
                            
                            Text("まだメモがありません")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            Text("「誰と会いましたか？」をタップして\n最初のメモを作成しましょう")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                        .padding(.bottom, 100)
                        }
                    }
                }
            }
            .background(Color.appBackground(for: colorScheme))
            .sheet(isPresented: $showingAddModal) {
                QuickAddView()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        generateDummyData()
                    }) {
                        Image(systemName: showSuccess ? "checkmark.circle.fill" : "sparkles")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(showSuccess ? .green : .brandPrimary)
                            .symbolEffect(.bounce, value: showSuccess)
                    }
                    .disabled(isGenerating)
                }
            }
        }
    }
    
    private func generateDummyData() {
        guard !isGenerating else { return }
        
        isGenerating = true
        showSuccess = false
        
        Task {
            // ダミーデータを生成
            DataSeeder.createSampleData(modelContext: modelContext)
            
            // メインスレッドでUI更新
            await MainActor.run {
                isGenerating = false
                showSuccess = true
                
                // 触覚フィードバック
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                // 1.5秒後にアイコンを元に戻す
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        showSuccess = false
                    }
                }
            }
        }
    }
}

struct MemoCard: View {
    let note: Note
    @Environment(\.colorScheme) var colorScheme
    
    private var person: Person? {
        note.meeting?.person
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left: Person Avatar
            if let person = person {
                if let imageData = person.iconImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.personColor(for: person.id))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text(person.initials)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        )
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text("?")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                    )
            }
            
            // Right: Content
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    if let person = person {
                        Text(person.name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: colorScheme == .dark ? "FFFFFF" : "1C1C1E"))
                    }
                    
                    Spacer()
                    
                    Text(dateFormatter.string(from: note.createdAt))
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                // Content
                Text(note.content)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(Color(hex: colorScheme == .dark ? "FFFFFF" : "1C1C1E"))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Category (if exists)
                if !note.category.isEmpty {
                    HStack(spacing: 4) {
                        Text(note.category)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.brandPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.brandPrimary.opacity(0.1))
                            )
                    }
                }
            }
        }
        .padding(.vertical, 16)
    }
}
