//
//  TranscriptBlock.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import Foundation
import SwiftData

@Model
final class TranscriptBlock {
    var id: UUID
    var text: String
    var isHighlighted: Bool // ハイライトされているか（重要項目として保存）
    var orderIndex: Int // 表示順序
    var userContextNote: String? // ユーザーが追記できるメモ
    var meeting: Meeting?
    
    init(text: String, isHighlighted: Bool = false, orderIndex: Int = 0, userContextNote: String? = nil, meeting: Meeting? = nil) {
        self.id = UUID()
        self.text = text
        self.isHighlighted = isHighlighted
        self.orderIndex = orderIndex
        self.userContextNote = userContextNote
        self.meeting = meeting
    }
}

