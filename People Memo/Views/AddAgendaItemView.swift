//
//  AddAgendaItemView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData

struct AddAgendaItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let meeting: Meeting
    let type: String // "Topic" or "Action"
    
    @State private var content: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(type == "Topic" ? "話したいこと" : "準備・To-Do") {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(type == "Topic" ? "トピックを追加" : "To-Doを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveAgendaItem()
                    }
                    .disabled(content.isEmpty)
                }
            }
        }
    }
    
    private func saveAgendaItem() {
        let maxIndex = (meeting.agendaItems ?? []).map { $0.orderIndex }.max() ?? -1
        let item = AgendaItem(
            content: content,
            isCompleted: false,
            type: type,
            orderIndex: maxIndex + 1,
            meeting: meeting
        )
        modelContext.insert(item)
        dismiss()
    }
}

#Preview {
    AddAgendaItemView(meeting: Meeting(date: Date(), isFuture: true), type: "Topic")
        .modelContainer(for: [Meeting.self, AgendaItem.self], inMemory: true)
}

