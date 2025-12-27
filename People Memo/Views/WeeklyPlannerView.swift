//
//  WeeklyPlannerView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData

struct WeeklyPlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Person.createdAt, order: .reverse) private var people: [Person]
    
    @State private var selectedPerson: Person?
    @State private var selectedDate: Date = Date()
    @State private var location: String = ""
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("誰と会いますか？") {
                    if people.isEmpty {
                        Text("まず人物を追加してください")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("人物", selection: $selectedPerson) {
                            Text("選択してください").tag(nil as Person?)
                            ForEach(people) { person in
                                HStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.7))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Text(person.initials)
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.white)
                                        )
                                    Text(person.name)
                                }
                                .tag(person as Person?)
                            }
                        }
                    }
                }
                
                Section("いつ会いますか？") {
                    DatePicker("日付", selection: $selectedDate, displayedComponents: [.date])
                }
                
                Section("場所（任意）") {
                    TextField("場所", text: $location)
                }
            }
            .navigationTitle("来週の予定を立てる")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveFutureMeeting()
                    }
                    .disabled(selectedPerson == nil)
                }
            }
        }
    }
    
    private func saveFutureMeeting() {
        guard let person = selectedPerson else { return }
        
        let meeting = Meeting(
            date: selectedDate,
            location: location,
            isFuture: true,
            person: person
        )
        modelContext.insert(meeting)
        dismiss()
    }
}

#Preview {
    WeeklyPlannerView()
        .modelContainer(for: [Person.self, Meeting.self], inMemory: true)
}

