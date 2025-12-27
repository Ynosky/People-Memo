//
//  AddMeetingView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData

struct AddMeetingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let person: Person
    
    @State private var date: Date = Date()
    @State private var location: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("会話情報") {
                    DatePicker("日付", selection: $date, displayedComponents: [.date])
                    TextField("場所（任意）", text: $location)
                }
            }
            .navigationTitle("会話を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveMeeting()
                    }
                }
            }
        }
    }
    
    private func saveMeeting() {
        let isFuture = date > Date()
        let meeting = Meeting(date: date, location: location, isFuture: isFuture, person: person)
        modelContext.insert(meeting)
        dismiss()
    }
}

#Preview {
    AddMeetingView(person: Person(name: "山田太郎"))
        .modelContainer(for: [Person.self, Meeting.self, Note.self], inMemory: true)
}

