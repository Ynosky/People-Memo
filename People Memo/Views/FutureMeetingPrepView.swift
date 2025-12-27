//
//  FutureMeetingPrepView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData

struct FutureMeetingPrepView: View {
    @Environment(\.modelContext) private var modelContext
    let meeting: Meeting
    @State private var showingAddTopic = false
    @State private var showingAddAction = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // ヘッダー情報
                VStack(alignment: .leading, spacing: 8) {
                    if let person = meeting.person {
                        HStack {
                            Circle()
                                .fill(Color.blue.opacity(0.7))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(person.initials)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                            
                            Text(person.name)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    
                    Text(dateFormatter.string(from: meeting.date))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if !meeting.location.isEmpty {
                        Text("場所: \(meeting.location)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                Divider()
                
                // 1. Review: 過去のハイライト
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("過去のハイライト")
                            .font(.headline)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    if let person = meeting.person {
                        PastHighlightsView(person: person)
                    } else {
                        Text("人物情報がありません")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                
                Divider()
                
                // 2. Topics: 話したいこと
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("話したいこと")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: { showingAddTopic = true }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    if meeting.pendingTopics.isEmpty {
                        Text("まだトピックがありません")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(meeting.pendingTopics, id: \.id) { topic in
                            AgendaItemRow(item: topic)
                                .padding(.horizontal)
                        }
                    }
                }
                
                Divider()
                
                // 3. To-Dos: 準備すること
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("準備・To-Do")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: { showingAddAction = true }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    if meeting.pendingActions.isEmpty {
                        Text("まだTo-Doがありません")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(meeting.pendingActions, id: \.id) { action in
                            AgendaItemRow(item: action)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTopic) {
            AddAgendaItemView(meeting: meeting, type: "Topic")
        }
        .sheet(isPresented: $showingAddAction) {
            AddAgendaItemView(meeting: meeting, type: "Action")
        }
    }
}

struct PastHighlightsView: View {
    let person: Person
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 過去の会話からハイライトされたブロックを取得
            if let meetings = person.meetings {
                let pastMeetings = meetings.filter { !$0.isFuture && $0.date < Date() }
                let allHighlights = pastMeetings.flatMap { $0.highlightedBlocks }
                
                if allHighlights.isEmpty {
                    Text("まだハイライトがありません")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(Array(allHighlights.prefix(10)), id: \.id) { block in
                        HighlightCard(block: block)
                    }
                }
            } else {
                Text("まだ会話記録がありません")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
}

struct HighlightCard: View {
    let block: TranscriptBlock
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(.caption)
            
            Text(block.text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(8)
    }
}

struct AgendaItemRow: View {
    @Environment(\.modelContext) private var modelContext
    let item: AgendaItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: {
                withAnimation {
                    item.isCompleted.toggle()
                }
            }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            
            Text(item.content)
                .font(.body)
                .strikethrough(item.isCompleted)
                .foregroundColor(item.isCompleted ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Person.self, Meeting.self, AgendaItem.self, TranscriptBlock.self, configurations: config)
    let person = Person(name: "山田太郎")
    let meeting = Meeting(date: Date().addingTimeInterval(86400 * 7), isFuture: true, person: person)
    
    return FutureMeetingPrepView(meeting: meeting)
        .modelContainer(container)
}

