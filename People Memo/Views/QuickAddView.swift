//
//  QuickAddView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData
import UIKit

struct QuickAddView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Person.name) private var people: [Person]
    
    @State private var selectedPerson: Person?
    @State private var showingPersonPicker = true
    @State private var showingAddPerson = false
    @State private var date: Date = Date()
    @State private var location: String = ""
    @State private var noteContent: String = ""
    
    var body: some View {
        NavigationStack {
            if showingPersonPicker {
                // 人物選択画面
                List {
                    Section {
                        ForEach(people) { person in
                            Button(action: {
                                selectedPerson = person
                                showingPersonPicker = false
                            }) {
                                HStack {
                                    if let imageData = person.iconImageData, let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Color.personColor(for: person.id))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Text(person.initials)
                                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                                    .foregroundColor(.white)
                                            )
                                    }
                                    
                                    Text(person.name)
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                            }
                        }
                    } header: {
                        Text("誰と会いましたか？")
                    }
                    
                    Section {
                        Button(action: {
                            showingAddPerson = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.brandPrimary)
                                Text("新しい人物を追加")
                                    .foregroundColor(.brandPrimary)
                            }
                        }
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
                }
                .sheet(isPresented: $showingAddPerson) {
                    AddPersonView()
                }
            } else if let person = selectedPerson {
                // メモ入力画面
                Form {
                    Section {
                        HStack {
                            if let imageData = person.iconImageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.personColor(for: person.id))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(person.initials)
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            Text(person.name)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                    }
                    
                    Section("会話情報") {
                        DatePicker("日付", selection: $date, displayedComponents: [.date])
                        TextField("場所（任意）", text: $location)
                    }
                    
                    Section("メモ") {
                        TextEditor(text: $noteContent)
                            .frame(minHeight: 150)
                    }
                }
                .navigationTitle("メモを追加")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("戻る") {
                            showingPersonPicker = true
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("保存") {
                            saveMeeting()
                        }
                        .disabled(noteContent.isEmpty)
                    }
                }
            }
        }
    }
    
    private func saveMeeting() {
        guard let person = selectedPerson else { return }
        
        let isFuture = date > Date()
        let meeting = Meeting(date: date, location: location, isFuture: isFuture, person: person)
        modelContext.insert(meeting)
        
        // メモも追加
        if !noteContent.isEmpty {
            let note = Note(
                content: noteContent,
                isImportant: false,
                category: "",
                meeting: meeting,
                createdAt: date
            )
            modelContext.insert(note)
        }
        
        dismiss()
    }
}


