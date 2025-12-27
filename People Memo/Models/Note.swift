//
//  Note.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID
    var content: String
    var isImportant: Bool // 振り返りに表示するかどうか
    var category: String // 趣味、仕事、家族など
    var createdAt: Date
    var lastReviewedAt: Date? // 最後に振り返りで確認した日時
    var reviewCount: Int // 振り返り回数
    var meeting: Meeting?
    
    init(content: String, isImportant: Bool = false, category: String = "", meeting: Meeting? = nil, createdAt: Date = Date()) {
        self.id = UUID()
        self.content = content
        self.isImportant = isImportant
        self.category = category
        self.createdAt = createdAt
        self.lastReviewedAt = nil
        self.reviewCount = 0
        self.meeting = meeting
    }
}

