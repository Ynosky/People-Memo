//
//  Meeting.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import Foundation
import SwiftData

@Model
final class Meeting {
    var id: UUID
    var date: Date
    var location: String
    var isFuture: Bool // 未来の予定かどうか
    @Relationship(deleteRule: .cascade, inverse: \Note.meeting) var notes: [Note]?
    @Relationship(deleteRule: .cascade, inverse: \TranscriptBlock.meeting) var transcriptBlocks: [TranscriptBlock]?
    @Relationship(deleteRule: .cascade, inverse: \AgendaItem.meeting) var agendaItems: [AgendaItem]?
    var person: Person?
    
    init(date: Date, location: String = "", isFuture: Bool = false, person: Person? = nil) {
        self.id = UUID()
        self.date = date
        self.location = location
        self.isFuture = isFuture
        self.person = person
        self.notes = []
        self.transcriptBlocks = []
        self.agendaItems = []
    }
    
    // ハイライトされたブロックのみを取得
    var highlightedBlocks: [TranscriptBlock] {
        (transcriptBlocks ?? []).filter { $0.isHighlighted }.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    // 未完了のTopicsを取得
    var pendingTopics: [AgendaItem] {
        (agendaItems ?? []).filter { $0.type == "Topic" && !$0.isCompleted }.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    // 未完了のActionsを取得
    var pendingActions: [AgendaItem] {
        (agendaItems ?? []).filter { $0.type == "Action" && !$0.isCompleted }.sorted { $0.orderIndex < $1.orderIndex }
    }
}

