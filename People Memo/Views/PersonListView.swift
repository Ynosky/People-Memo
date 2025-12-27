//
//  PersonListView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData
import UIKit

struct PersonListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Person.createdAt, order: .reverse) private var allPeople: [Person]
    @State private var showingAddPerson = false
    @State private var selectedTag: String? = nil
    @Environment(\.colorScheme) var colorScheme
    
    // 選択されたタグでフィルタリング
    private var filteredPeople: [Person] {
        guard let tag = selectedTag else {
            return allPeople
        }
        return allPeople.filter { $0.tags.contains(tag) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // タグフィルターバー
                    TagFilterBar(selectedTag: $selectedTag)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                    
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredPeople) { person in
                                PersonInteractiveCard(person: person)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .padding(.bottom, 100) // FloatingTabBarのスペース
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("人物")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color.primaryText(for: colorScheme))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPerson = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.primaryText(for: colorScheme))
                    }
                }
            }
            .sheet(isPresented: $showingAddPerson) {
                AddPersonView()
            }
        }
    }
}

struct PersonInteractiveCard: View {
    let person: Person
    @State private var isPressed = false
    @State private var previewScale: CGFloat = 1.0
    @Environment(\.colorScheme) var colorScheme
    
    private var sortedMeetings: [Meeting] {
        (person.meetings ?? []).sorted { $0.date > $1.date }
    }
    
    private var latestNote: Note? {
        guard let meetings = person.meetings else { return nil }
        let allNotes = meetings.compactMap { $0.notes ?? [] }.flatMap { $0 }
        return allNotes.sorted { $0.createdAt > $1.createdAt }.first
    }
    
    private var statusText: String {
        guard let days = person.daysSinceLastMeeting else {
            return "未会話"
        }
        
        if days == 0 {
            return "今日"
        } else if days == 1 {
            return "昨日"
        } else {
            return "\(days)日前"
        }
    }
    
    private var statusColor: Color {
        guard let days = person.daysSinceLastMeeting else {
            return .gray
        }
        
        if days <= 7 {
            return .green
        } else if days <= 30 {
            return .orange
        } else {
            // 30日以上経過（ご無沙汰）はSoft Coralを使用
            return .brandSecondary
        }
    }
    
    var body: some View {
        NavigationLink(destination: PersonDetailView(person: person)) {
            HStack(spacing: 16) {
                // Left: 大きなアバター（円形）
                if let imageData = person.iconImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                } else {
                    Circle()
                        .fill(Color.personColor(for: person.id))
                        .frame(width: 70, height: 70)
                        .overlay(
                            Text(person.initials)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        )
                }
                
                // Center: 名前とメモ
                VStack(alignment: .leading, spacing: 6) {
                    Text(person.name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color.primaryText(for: colorScheme))
                        .lineLimit(1)
                    
                    if let note = latestNote, !note.content.isEmpty {
                        Text(note.content)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else if let lastMeeting = sortedMeetings.first {
                        Text("\(dateFormatter.string(from: lastMeeting.date))に会話")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("まだ会話がありません")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.6))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Right: ステータスバッジ（Pill shape）
                Text(statusText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.15))
                    )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThickMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
            .scaleEffect(isPressed ? 0.98 : previewScale)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: previewScale)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: 10, pressing: { pressing in
            withAnimation {
                isPressed = pressing
                if pressing {
                    previewScale = 1.02
                } else {
                    previewScale = 1.0
                }
            }
        }, perform: {})
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
}

#Preview {
    PersonListView()
        .modelContainer(for: [Person.self, Meeting.self, Note.self], inMemory: true)
}
