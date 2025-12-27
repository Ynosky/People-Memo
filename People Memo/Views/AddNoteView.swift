//
//  AddNoteView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData

struct AddNoteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let meeting: Meeting
    
    @State private var content: String = ""
    @State private var category: String = ""
    @State private var isImportant: Bool = false
    
    private let categories = ["趣味", "仕事", "家族", "健康", "旅行", "その他"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("メモ内容") {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                }
                
                Section("カテゴリー") {
                    Picker("カテゴリー", selection: $category) {
                        Text("選択なし").tag("")
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }
                
                Section("設定") {
                    Toggle("振り返りに表示", isOn: $isImportant)
                }
            }
            .navigationTitle("メモを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveNote()
                    }
                    .disabled(content.isEmpty)
                }
            }
        }
    }
    
    private func saveNote() {
        let note = Note(content: content, isImportant: isImportant, category: category, meeting: meeting)
        modelContext.insert(note)
        dismiss()
    }
}

#Preview {
    AddNoteView(meeting: Meeting(date: Date()))
        .modelContainer(for: [Person.self, Meeting.self, Note.self], inMemory: true)
}

