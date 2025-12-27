//
//  AgendaItem.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import Foundation
import SwiftData

enum AgendaItemType: String, Codable {
    case topic = "Topic"
    case action = "Action"
}

@Model
final class AgendaItem {
    var id: UUID
    var content: String
    var isCompleted: Bool
    var type: String // "Topic" or "Action"
    var orderIndex: Int
    var meeting: Meeting?
    
    init(content: String, isCompleted: Bool = false, type: String = "Topic", orderIndex: Int = 0, meeting: Meeting? = nil) {
        self.id = UUID()
        self.content = content
        self.isCompleted = isCompleted
        self.type = type
        self.orderIndex = orderIndex
        self.meeting = meeting
    }
    
    var agendaType: AgendaItemType {
        get {
            AgendaItemType(rawValue: type) ?? .topic
        }
        set {
            type = newValue.rawValue
        }
    }
}

