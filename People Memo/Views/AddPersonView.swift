//
//  AddPersonView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData

struct AddPersonView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Person.createdAt) private var allPeople: [Person]
    @Environment(\.colorScheme) var colorScheme
    
    @State private var name: String = ""
    @State private var relationshipTag: String = ""
    @State private var tagsText: String = ""
    @State private var selectedTags: Set<String> = []
    
    // 既存のタグ候補
    private var existingTags: [String] {
        let allTags = allPeople.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("名前", text: $name)
                    TextField("関係性（例: 友人、同僚、家族）", text: $relationshipTag)
                }
                
                Section("タグ") {
                    // テキスト入力（カンマ区切り）
                    TextField("タグ（カンマ区切りで入力）", text: $tagsText)
                        .onChange(of: tagsText) { oldValue, newValue in
                            // カンマ区切りでタグをパース
                            let tags = newValue.split(separator: ",")
                                .map { $0.trimmingCharacters(in: .whitespaces) }
                                .filter { !$0.isEmpty }
                            selectedTags = Set(tags)
                        }
                    
                    // 既存タグ候補
                    if !existingTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(existingTags, id: \.self) { tag in
                                    Button(action: {
                                        if selectedTags.contains(tag) {
                                            selectedTags.remove(tag)
                                        } else {
                                            selectedTags.insert(tag)
                                        }
                                        updateTagsText()
                                    }) {
                                        Text(tag)
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(selectedTags.contains(tag) ? .white : Color.primaryText(for: colorScheme))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(selectedTags.contains(tag) ? Color.brandPrimary : Color.clear)
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(
                                                                selectedTags.contains(tag) ? Color.brandPrimary : Color.cardBorder(for: colorScheme),
                                                                lineWidth: selectedTags.contains(tag) ? 0 : 1
                                                            )
                                                    )
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
            }
            .navigationTitle("人物を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        savePerson()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func savePerson() {
        let tags = Array(selectedTags)
        let person = Person(name: name, relationshipTag: relationshipTag, tags: tags)
        modelContext.insert(person)
        dismiss()
    }
    
    private func updateTagsText() {
        tagsText = Array(selectedTags).sorted().joined(separator: ", ")
    }
}

#Preview {
    AddPersonView()
        .modelContainer(for: [Person.self, Meeting.self, Note.self], inMemory: true)
}

