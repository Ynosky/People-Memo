//
//  Person.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import Foundation
import SwiftData

@Model
final class Person {
    var id: UUID
    var name: String
    var iconImageData: Data?
    var createdAt: Date
    var relationshipTag: String // 関係性タグ（友人、同僚、家族など）
    var nextReminderDate: Date? // 次のリマインダー日時
    var tags: [String] // グループタグ（Work, Hobby, School, Family, Drinking Buddy）
    @Relationship(deleteRule: .cascade, inverse: \Meeting.person) var meetings: [Meeting]?
    
    init(name: String, iconImageData: Data? = nil, relationshipTag: String = "", tags: [String] = [], createdAt: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.iconImageData = iconImageData
        self.createdAt = createdAt
        self.relationshipTag = relationshipTag
        self.nextReminderDate = nil
        self.tags = tags
        self.meetings = []
    }
    
    // イニシャルを取得するヘルパー
    var initials: String {
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        } else if !name.isEmpty {
            return String(name.prefix(1))
        }
        return "?"
    }
    
    // 最後に会ってからの経過日数を計算
    var daysSinceLastMeeting: Int? {
        guard let meetings = meetings, !meetings.isEmpty else {
            return nil
        }
        
        let now = Date()
        let pastMeetings = meetings.filter { !$0.isFuture && $0.date <= now }
        
        guard let lastMeeting = pastMeetings.max(by: { $0.date < $1.date }) else {
            return nil
        }
        
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: lastMeeting.date, to: now).day
        return days
    }
    
    // 軌道進行度を計算（0.0=今日会った, 1.0=疎遠）
    var orbitProgress: Double {
        guard let days = daysSinceLastMeeting else {
            return 1.0 // 未記録は最も外側
        }
        
        // 180日（約6ヶ月）を最大値として正規化
        let maxDays: Double = 180
        let progress = min(Double(days) / maxDays, 1.0)
        return progress
    }
    
    // タグに基づく角度を計算（0-2π）
    func angleForTag(_ tag: String, totalTags: [String]) -> Double {
        guard let index = totalTags.firstIndex(of: tag) else {
            return 0
        }
        let tagCount = Double(totalTags.count)
        return (Double(index) / tagCount) * 2 * .pi
    }
}

