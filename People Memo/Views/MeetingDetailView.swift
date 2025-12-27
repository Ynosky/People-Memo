//
//  MeetingDetailView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData

struct MeetingDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let meeting: Meeting
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            if meeting.isFuture {
                // 未来の予定の場合は準備画面を表示
                FutureMeetingPrepView(meeting: meeting)
            } else {
                // 過去の会話の場合は通常の詳細画面
                PastMeetingDetailView(meeting: meeting)
            }
        }
        .navigationTitle(meeting.isFuture ? "予定詳細" : "会話詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }
}

struct PastMeetingDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    let meeting: Meeting
    @State private var transcriptText: String = ""
    @State private var isEditingTranscript: Bool = false
    @State private var isHighlightMode: Bool = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    private var personColor: Color {
        if let person = meeting.person {
            return Color.personColor(for: person.id)
        }
        return Color.primaryMint
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                // ヘッダー情報
                VStack(alignment: .leading, spacing: 16) {
                    if let person = meeting.person {
                        HStack(spacing: 16) {
                            PersonBubble(person: person, size: 70, borderWidth: 4)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(person.name)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text(dateFormatter.string(from: meeting.date))
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                                
                                if !meeting.location.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(personColor)
                                        Text(meeting.location)
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                    }
                }
                .padding(24)
                .cardStyle(cornerRadius: 24, backgroundColor: personColor.opacity(0.1))
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // 対談ログセクション
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("対談ログ")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if !isHighlightMode {
                            Button(action: {
                                if isEditingTranscript {
                                    // 保存してハイライトモードへ
                                    saveTranscript()
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        isHighlightMode = true
                                        isEditingTranscript = false
                                    }
                                } else {
                                    // 編集モードへ
                                    loadTranscript()
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        isEditingTranscript = true
                                    }
                                }
                            }) {
                                Text(isEditingTranscript ? "ハイライトモードへ" : "編集")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(personColor)
                                    .cornerRadius(20)
                            }
                            .bouncy()
                        } else {
                            Button(action: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    isHighlightMode = false
                                }
                            }) {
                                Text("編集モードへ")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(personColor)
                                    .cornerRadius(20)
                            }
                            .bouncy()
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    if isEditingTranscript {
                        // テキスト編集モード
                        TextEditor(text: $transcriptText)
                            .frame(minHeight: 200)
                            .padding(16)
                            .background(Color.cardBackground(for: colorScheme))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(personColor.opacity(0.3), lineWidth: 2)
                            )
                            .padding(.horizontal, 20)
                    } else if isHighlightMode {
                        // ハイライトモード
                        HighlightableTranscriptView(meeting: meeting)
                    } else {
                        // プレビューモード（既存のブロックを表示）
                        if let blocks = meeting.transcriptBlocks, !blocks.isEmpty {
                            HighlightableTranscriptView(meeting: meeting)
                        } else {
                            Button(action: {
                                loadTranscript()
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    isEditingTranscript = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20, design: .rounded))
                                    Text("対談ログを追加")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(personColor)
                                .cornerRadius(24)
                            }
                            .bouncy()
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.top, 8)
                
                // ノート一覧
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("メモ")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    if let notes = meeting.notes, !notes.isEmpty {
                        ForEach(notes) { note in
                            MeetingNoteCard(note: note)
                                .padding(.horizontal, 20)
                        }
                    } else {
                        Text("まだメモがありません")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                }
            }
        }
    }
    
    private func loadTranscript() {
        if let blocks = meeting.transcriptBlocks, !blocks.isEmpty {
            transcriptText = TranscriptHelper.reconstructText(from: blocks)
        } else {
            transcriptText = ""
        }
    }
    
    private func saveTranscript() {
        if !transcriptText.isEmpty {
            TranscriptHelper.updateBlocks(from: transcriptText, meeting: meeting, modelContext: modelContext)
        }
    }
}

struct MeetingNoteCard: View {
    let note: Note
    
    @State private var rotation: Double = 0
    
    private var noteColor: Color {
        Color.primaryMint
    }
    
    init(note: Note) {
        self.note = note
        // 各ノートにランダムな回転を付与
        _rotation = State(initialValue: Double.random(in: -2...2))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !note.category.isEmpty {
                Text(note.category)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(noteColor)
                    .cornerRadius(16)
            }
            
            Text(note.content)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .lineSpacing(4)
            
            if note.isImportant {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                    Text("重要")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(cornerRadius: 24, backgroundColor: noteColor.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(noteColor.opacity(0.3), lineWidth: 2)
        )
        .rotationEffect(.degrees(rotation))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 2, y: 4)
    }
}

#Preview {
    MeetingDetailView(meeting: Meeting(date: Date(), location: "カフェ"))
        .modelContainer(for: [Person.self, Meeting.self, Note.self, TranscriptBlock.self, AgendaItem.self], inMemory: true)
}

