//
//  PersonDetailView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData
import UIKit

struct PersonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    let person: Person
    @State private var showingAddMeeting = false
    @State private var reminderDate: Date = Date()
    @State private var showingReminderAlert = false
    @State private var reminderAlertMessage = ""
    
    private var sortedMeetings: [Meeting] {
        (person.meetings ?? []).sorted { $0.date > $1.date }
    }
    
    private var personColor: Color {
        Color.personColor(for: person.id)
    }
    
    var body: some View {
        ZStack {
            Color.appBackground(for: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // ヘッダー
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 20) {
                            // アバター（角丸四角形）
                            if let imageData = person.iconImageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.cardBorder(for: colorScheme), lineWidth: 1)
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.personColor(for: person.id))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Text(person.initials)
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(person.name)
                                    .font(.system(size: 28, weight: .heavy))
                                    .foregroundColor(Color.primaryText(for: colorScheme))
                                
                                if !person.relationshipTag.isEmpty {
                                    Text(person.relationshipTag)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    
                    // コンテンツエリア
                    VStack(alignment: .leading, spacing: 24) {
                        // リマインダー設定セクション
                        ReminderSection(
                            person: person,
                            reminderDate: $reminderDate,
                            showingAlert: $showingReminderAlert,
                            alertMessage: $reminderAlertMessage
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // 会話履歴
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("会話履歴")
                                    .font(.system(size: 24, weight: .heavy))
                                    .foregroundColor(Color.primaryText(for: colorScheme))
                                
                                Spacer()
                                
                                Button(action: { showingAddMeeting = true }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(Color.primaryText(for: colorScheme))
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            if sortedMeetings.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray.opacity(0.3))
                                    
                                    Text("まだ会話記録がありません")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                ForEach(sortedMeetings) { meeting in
                                    StickyNoteMeetingRow(meeting: meeting, personColor: personColor)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddMeeting) {
            AddMeetingView(person: person)
        }
        .onAppear {
            if let nextReminder = person.nextReminderDate {
                reminderDate = nextReminder
            }
        }
        .alert("リマインダー", isPresented: $showingReminderAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(reminderAlertMessage)
        }
    }
}

struct ReminderSection: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    let person: Person
    @Binding var reminderDate: Date
    @Binding var showingAlert: Bool
    @Binding var alertMessage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("リマインダー設定")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.primaryText(for: colorScheme))
            
            DatePicker(
                "リマインダー日時",
                selection: $reminderDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
            .font(.system(size: 16))
            
            HStack {
                if let nextReminder = person.nextReminderDate {
                    Text("設定済み: \(formatReminderDate(nextReminder))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { setReminder() }) {
                    Text("設定")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.brandPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                if person.nextReminderDate != nil {
                    Button(action: { cancelReminder() }) {
                        Text("解除")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.primaryText(for: colorScheme))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.cardBackground(for: colorScheme))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.cardBorder(for: colorScheme), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground(for: colorScheme))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.cardBorder(for: colorScheme), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func setReminder() {
        NotificationManager.shared.scheduleReminder(for: person, date: reminderDate) { success, errorMessage in
            if success {
                person.nextReminderDate = reminderDate
                alertMessage = "リマインダーを設定しました。"
            } else {
                alertMessage = errorMessage ?? "リマインダーの設定に失敗しました。"
            }
            showingAlert = true
        }
    }
    
    private func cancelReminder() {
        NotificationManager.shared.cancelReminder(for: person)
        person.nextReminderDate = nil
        alertMessage = "リマインダーを解除しました。"
        showingAlert = true
    }
    
    private func formatReminderDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日 H:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

struct StickyNoteMeetingRow: View {
    @Environment(\.colorScheme) var colorScheme
    let meeting: Meeting
    let personColor: Color
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(dateFormatter.string(from: meeting.date))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.primaryText(for: colorScheme))
                
                if !meeting.location.isEmpty {
                    Text("・\(meeting.location)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            if let notes = meeting.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(notes) { note in
                        StickyNoteCard(note: note, personColor: personColor)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground(for: colorScheme))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.cardBorder(for: colorScheme), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct StickyNoteCard: View {
    @Environment(\.colorScheme) var colorScheme
    let note: Note
    let personColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !note.category.isEmpty {
                Text(note.category)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            Text(note.content)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.primaryText(for: colorScheme))
            
            if note.isImportant {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    Text("重要")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground(for: colorScheme))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.cardBorder(for: colorScheme), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack {
        PersonDetailView(person: Person(name: "山田太郎", relationshipTag: "友人"))
    }
    .modelContainer(for: [Person.self, Meeting.self, Note.self], inMemory: true)
}
