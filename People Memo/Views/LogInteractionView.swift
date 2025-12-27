//
//  LogInteractionView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData
import UIKit

struct LogInteractionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Query(sort: \Person.name) private var people: [Person]
    
    @State private var selectedPerson: Person?
    @State private var showingPersonPicker = false
    @State private var showingDatePicker = false
    @State private var date: Date = Date()
    @State private var noteContent: String = ""
    @State private var isHighlightMode: Bool = false
    @State private var highlightedTexts: Set<String> = []
    
    // フォーカス管理
    @FocusState private var isMemoFocused: Bool
    
    // 日付フォーマッター
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Area (Title & Properties)
                VStack(alignment: .leading, spacing: 12) {
                    // Person (Title)
                    Button(action: {
                        // 触覚フィードバック
                        let selectionFeedback = UISelectionFeedbackGenerator()
                        selectionFeedback.selectionChanged()
                        
                        showingPersonPicker = true
                    }) {
                        HStack(spacing: 0) {
                            if let person = selectedPerson {
                                Text(person.name)
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.primaryText(for: colorScheme))
                            } else {
                                Text("人物を選択...")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Date (Property)
                    Button(action: {
                        // 触覚フィードバック
                        let selectionFeedback = UISelectionFeedbackGenerator()
                        selectionFeedback.selectionChanged()
                        
                        showingDatePicker = true
                    }) {
                        HStack(spacing: 6) {
                            Text("📅")
                                .font(.system(size: 14))
                            Text(dateFormatter.string(from: date))
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                Divider()
                    .padding(.horizontal, 20)
                
                // Editor Area (Body) - Mode Switch
                ZStack {
                    if isHighlightMode {
                        // Highlight Mode: Interactive Log View
                        if noteContent.isEmpty {
                            VStack {
                                Spacer()
                                Text("テキストを入力してから\nハイライトモードに切り替えてください")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            InteractiveLogView(
                                text: $noteContent,
                                highlightedTexts: $highlightedTexts
                            )
                        }
                    } else {
                        // Writing Mode: Text Editor
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                ZStack(alignment: .topLeading) {
                                    // Placeholder
                                    if noteContent.isEmpty {
                                        Text("ここに会話の内容やメモを自由に書いてください...")
                                            .font(.system(size: 17, weight: .regular, design: .rounded))
                                            .foregroundColor(.secondary.opacity(0.4))
                                            .padding(.horizontal, 20)
                                            .padding(.top, 20)
                                    }
                                    
                                    // Text Editor
                                    TextEditor(text: $noteContent)
                                        .font(.system(size: 17, weight: .regular, design: .rounded))
                                        .foregroundColor(Color.primaryText(for: colorScheme))
                                        .scrollContentBackground(.hidden)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 16)
                                        .focused($isMemoFocused)
                                        .lineSpacing(6)
                                        .onChange(of: noteContent) { oldValue, newValue in
                                            // タイピング時の触覚フィードバック（微細）
                                            if newValue.count > oldValue.count {
                                                let softFeedback = UIImpactFeedbackGenerator(style: .soft)
                                                softFeedback.impactOccurred()
                                            }
                                        }
                                }
                                .frame(minHeight: 400)
                            }
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: isHighlightMode)
            }
            .background(Color.appBackground(for: colorScheme))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.primaryText(for: colorScheme))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // モード切替ボタン
                        Button(action: {
                            // ハイライトモードに切り替える場合はキーボードを閉じる
                            if !isHighlightMode {
                                isMemoFocused = false
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                            
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isHighlightMode.toggle()
                            }
                            
                            // 触覚フィードバック
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        }) {
                            Image(systemName: isHighlightMode ? "pencil" : "highlighter")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color.primaryText(for: colorScheme))
                        }
                        
                        // 完了ボタン
                        Button(action: {
                            saveMeeting()
                        }) {
                            Text("完了")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(canSave ? Color.brandPrimary : .secondary)
                        }
                        .disabled(!canSave)
                    }
                }
            }
            .sheet(isPresented: $showingPersonPicker) {
                PersonPickerSheet(selectedPerson: $selectedPerson)
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(date: $date)
            }
            .onAppear {
                // 自動フォーカス
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isMemoFocused = true
                }
            }
        }
    }
    
    private var canSave: Bool {
        selectedPerson != nil && !noteContent.isEmpty
    }
    
    private func saveMeeting() {
        guard let person = selectedPerson else { return }
        
        let isFuture = date > Date()
        let meeting = Meeting(date: date, location: "", isFuture: isFuture, person: person)
        modelContext.insert(meeting)
        
        // メモを追加（ハイライト情報を含む）
        let highlightedArray = Array(highlightedTexts)
        let note = Note(
            content: noteContent,
            isImportant: false,
            category: "",
            highlightedTexts: highlightedArray,
            meeting: meeting,
            createdAt: date
        )
        modelContext.insert(note)
        
        // 触覚フィードバック
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        dismiss()
    }
}

// MARK: - Person Picker Sheet

struct PersonPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Person.name) private var allPeople: [Person]
    @Binding var selectedPerson: Person?
    @State private var showingAddPerson = false
    @State private var searchText: String = ""
    @State private var selectedTag: String? = nil
    @Environment(\.colorScheme) var colorScheme
    
    // タグと検索テキストでフィルタリング
    private var filteredPeople: [Person] {
        var filtered = allPeople
        
        // タグでフィルタリング
        if let tag = selectedTag {
            filtered = filtered.filter { $0.tags.contains(tag) }
        }
        
        // 検索テキストでフィルタリング
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // タグフィルターバー
                TagFilterBar(selectedTag: $selectedTag)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                
                List {
                    Section {
                        ForEach(filteredPeople) { person in
                            Button(action: {
                                // 触覚フィードバック
                                let selectionFeedback = UISelectionFeedbackGenerator()
                                selectionFeedback.selectionChanged()
                                
                                selectedPerson = person
                                dismiss()
                            }) {
                                HStack(spacing: 12) {
                                    if let imageData = person.iconImageData, let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 44, height: 44)
                                            .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Color.personColor(for: person.id))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Text(person.initials)
                                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                                    .foregroundColor(.white)
                                            )
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(person.name)
                                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                                            .foregroundColor(.primary)
                                        
                                        if !person.relationshipTag.isEmpty {
                                            Text(person.relationshipTag)
                                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedPerson?.id == person.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.brandPrimary)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } header: {
                        Text("人物を選択")
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
            }
            .searchable(text: $searchText, prompt: "人物を検索")
            .navigationTitle("人物を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddPerson) {
                AddPersonView()
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var date: Date
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker("", selection: $date, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding()
            }
            .navigationTitle("日付を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        // 触覚フィードバック
                        let selectionFeedback = UISelectionFeedbackGenerator()
                        selectionFeedback.selectionChanged()
                        
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
