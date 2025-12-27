//
//  PreviewData.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import Foundation
import SwiftData

class PreviewData {
    static func createSampleData(modelContext: ModelContext) {
        // サンプル人物を作成
        let person1 = Person(name: "山田太郎", relationshipTag: "友人")
        let person2 = Person(name: "佐藤花子", relationshipTag: "同僚")
        let person3 = Person(name: "鈴木一郎", relationshipTag: "家族")
        
        modelContext.insert(person1)
        modelContext.insert(person2)
        modelContext.insert(person3)
        
        // 過去数ヶ月分のミーティングを作成
        let calendar = Calendar.current
        let today = Date()
        
        // 山田太郎とのミーティング
        for i in 0..<5 {
            if let date = calendar.date(byAdding: .day, value: -(i * 7), to: today) {
                let meeting = Meeting(date: date, location: "カフェ", person: person1)
                modelContext.insert(meeting)
                
                // ノートを追加
                let note1 = Note(
                    content: "最近読んでいる本について話した。SF小説が好きだと言っていた。",
                    isImportant: true,
                    category: "趣味",
                    meeting: meeting,
                    createdAt: date
                )
                let note2 = Note(
                    content: "来週の週末に一緒に映画を見に行く約束をした。",
                    isImportant: false,
                    category: "その他",
                    meeting: meeting,
                    createdAt: date
                )
                modelContext.insert(note1)
                modelContext.insert(note2)
            }
        }
        
        // 佐藤花子とのミーティング
        for i in 0..<3 {
            if let date = calendar.date(byAdding: .day, value: -(i * 14), to: today) {
                let meeting = Meeting(date: date, location: "オフィス", person: person2)
                modelContext.insert(meeting)
                
                let note = Note(
                    content: "新しいプロジェクトについて相談。来月から始まる予定。",
                    isImportant: true,
                    category: "仕事",
                    meeting: meeting,
                    createdAt: date
                )
                modelContext.insert(note)
            }
        }
        
        // 鈴木一郎とのミーティング
        for i in 0..<4 {
            if let date = calendar.date(byAdding: .day, value: -(i * 10), to: today) {
                let meeting = Meeting(date: date, location: "自宅", person: person3)
                modelContext.insert(meeting)
                
                let note = Note(
                    content: "健康診断の結果について話した。特に問題なし。",
                    isImportant: i == 0, // 最新のものだけ重要フラグ
                    category: "健康",
                    meeting: meeting,
                    createdAt: date
                )
                modelContext.insert(note)
            }
        }
        
        // さらに過去のデータ（2-3ヶ月前）
        if let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: today) {
            let meeting = Meeting(date: twoMonthsAgo, location: "レストラン", person: person1)
            modelContext.insert(meeting)
            
            let note = Note(
                content: "旅行の話をした。沖縄に行きたいと言っていた。",
                isImportant: true,
                category: "旅行",
                meeting: meeting,
                createdAt: twoMonthsAgo
            )
            modelContext.insert(note)
        }
    }
}

