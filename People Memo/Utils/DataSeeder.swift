//
//  DataSeeder.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import Foundation
import SwiftData

class DataSeeder {
    // MARK: - Content Categories
    
    // Category A: Casual/Status (70%)
    private static let casualTexts: [String] = [
        "来週のスケジュールを調整しましょう。",
        "最近、ジムに通い始めました。",
        "お土産ありがとうございます。美味しかったです。",
        "例のプロジェクト、少し遅れ気味です。",
        "今度の週末、どこか行きませんか？",
        "新しいカフェがオープンしたらしいです。",
        "昨日の会議、どうでした？",
        "来月のイベント、参加しますか？",
        "最近、忙しくてなかなか会えませんね。",
        "天気が良くなってきましたね。",
        "先週のプレゼン、お疲れ様でした。",
        "今度の飲み会、楽しみです。",
        "新しい映画、見ましたか？",
        "最近、読書にはまっています。",
        "来週の打ち合わせ、場所はどこにしますか？",
        "お元気そうで何よりです。",
        "先日はありがとうございました。",
        "今度、一緒にランチしませんか？",
        "新しいレストラン、行ってみたいです。",
        "最近、運動不足を感じています。"
    ]
    
    // Category B: Insight/Learning (30%)
    private static let insightTexts: [String] = [
        "リーダーシップとは、人を動かすことではなく、人が動きたくなる環境を作ることだ。",
        "習慣化のコツは、やる気ではなく『トリガー』を設計することらしい。",
        "マーケティングの基本は、顧客の『不』を解消することにある。",
        "投資の神様が言っていた、『他人と逆を行く勇気』が必要だ。",
        "睡眠の質を上げるには、寝る90分前にお風呂に入ると良い。",
        "成功する人は、失敗を恐れずに行動する人ではなく、失敗から学ぶ人だ。",
        "コミュニケーションで最も重要なのは、話すことではなく聞くこと。",
        "時間管理の本質は、優先順位を決めることではなく、『やらないこと』を決めること。",
        "ストレスは悪いものではなく、適度なストレスが成長を促す。",
        "読書は知識を得るためではなく、思考の枠組みを変えるためにある。",
        "チームワークとは、全員が同じ方向を向くことではなく、それぞれの強みを活かすこと。",
        "イノベーションは、新しいものを作ることではなく、既存のものを組み合わせること。",
        "目標達成の鍵は、大きな目標を立てることではなく、小さな習慣を続けること。",
        "判断力は、情報を集めることではなく、不要な情報を捨てることから生まれる。",
        "人を動かすには、論理ではなく感情に訴えかけることが重要だ。",
        "集中力を高めるには、マルチタスクをやめて、一つのことに没頭すること。",
        "学び続けることが、変化の激しい時代を生き抜く唯一の方法だ。",
        "問題解決の第一歩は、問題を正しく定義することから始まる。",
        "信頼関係は、一度築けば永遠ではなく、日々の小さな行動で維持される。",
        "成功の定義は人それぞれだが、共通しているのは『成長し続けること』だ。"
    ]
    
    // MARK: - Main Seeding Function
    
    static func createSampleData(modelContext: ModelContext) {
        // タグセット
        let allTags = ["Work", "Hobby", "School", "Family", "Drinking Buddy"]
        
        // サンプル人物を作成（タグを偏りを持たせて付与）
        let person1 = Person(name: "山田太郎", relationshipTag: "友人", tags: ["Hobby", "Drinking Buddy"])
        let person2 = Person(name: "佐藤花子", relationshipTag: "同僚", tags: ["Work"])
        let person3 = Person(name: "鈴木一郎", relationshipTag: "家族", tags: ["Family"])
        let person4 = Person(name: "田中由美", relationshipTag: "メンター", tags: ["Work", "School"])
        let person5 = Person(name: "伊藤健", relationshipTag: "ビジネスパートナー", tags: ["Work"])
        
        // 追加の人物を生成（タグの偏りを作る）
        var additionalPeople: [Person] = []
        
        // Workタグの人物を多めに
        for i in 1...4 {
            let tags = ["Work"]
            let person = Person(name: "同僚\(i)", relationshipTag: "同僚", tags: tags)
            additionalPeople.append(person)
            modelContext.insert(person)
        }
        
        // Hobbyタグの人物
        for i in 1...3 {
            let tags = ["Hobby"]
            let person = Person(name: "趣味仲間\(i)", relationshipTag: "友人", tags: tags)
            additionalPeople.append(person)
            modelContext.insert(person)
        }
        
        // Familyタグの人物
        for i in 1...2 {
            let tags = ["Family"]
            let person = Person(name: "家族\(i)", relationshipTag: "家族", tags: tags)
            additionalPeople.append(person)
            modelContext.insert(person)
        }
        
        // Schoolタグの人物
        for i in 1...2 {
            let tags = ["School"]
            let person = Person(name: "学生時代\(i)", relationshipTag: "友人", tags: tags)
            additionalPeople.append(person)
            modelContext.insert(person)
        }
        
        // Drinking Buddyタグの人物
        for i in 1...2 {
            let tags = ["Drinking Buddy"]
            let person = Person(name: "飲み友達\(i)", relationshipTag: "友人", tags: tags)
            additionalPeople.append(person)
            modelContext.insert(person)
        }
        
        modelContext.insert(person1)
        modelContext.insert(person2)
        modelContext.insert(person3)
        modelContext.insert(person4)
        modelContext.insert(person5)
        
        // 過去数ヶ月分のミーティングを作成
        let calendar = Calendar.current
        let today = Date()
        
        // 各人物とのミーティングを生成
        let people = [person1, person2, person3, person4, person5] + additionalPeople
        let locations = ["カフェ", "オフィス", "自宅", "レストラン", "オンライン"]
        
        for (index, person) in people.enumerated() {
            // 各人物に対して5-8回のミーティングを生成
            let meetingCount = Int.random(in: 5...8)
            
            for i in 0..<meetingCount {
                // 過去1-3ヶ月の範囲でランダムな日付を生成
                let daysAgo = Int.random(in: 1...90) + (i * 7)
                if let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                    let location = locations[index % locations.count]
                    let meeting = Meeting(date: date, location: location, isFuture: false, person: person)
                    modelContext.insert(meeting)
                    
                    // TranscriptBlockを生成（会話ログをシミュレート）
                    generateTranscriptBlocks(for: meeting, modelContext: modelContext)
                    
                    // ノートも追加（従来の機能との互換性のため）
                    if i % 2 == 0 {
                        let note = Note(
                            content: generateNoteContent(),
                            isImportant: Bool.random(),
                            category: ["趣味", "仕事", "家族", "健康", "その他"].randomElement() ?? "その他",
                            meeting: meeting,
                            createdAt: date
                        )
                        modelContext.insert(note)
                    }
                }
            }
        }
        
        // さらに過去のデータ（2-3ヶ月前）も追加
        for person in [person1, person2, person3] {
            if let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: today) {
                let meeting = Meeting(date: twoMonthsAgo, location: "レストラン", isFuture: false, person: person)
                modelContext.insert(meeting)
                generateTranscriptBlocks(for: meeting, modelContext: modelContext)
            }
        }
    }
    
    // MARK: - Transcript Block Generation
    
    private static func generateTranscriptBlocks(for meeting: Meeting, modelContext: ModelContext) {
        // 会話の長さをランダムに決定（5-15ブロック）
        let blockCount = Int.random(in: 5...15)
        var transcriptText = ""
        
        for i in 0..<blockCount {
            // 30%の確率でInsight、70%の確率でCasualを選択
            let isInsight = Double.random(in: 0...1) < 0.3
            let selectedText = isInsight 
                ? insightTexts.randomElement() ?? insightTexts[0]
                : casualTexts.randomElement() ?? casualTexts[0]
            
            // ハイライト確率を決定
            let shouldHighlight: Bool
            if isInsight {
                // Insightは80%の確率でハイライト
                shouldHighlight = Double.random(in: 0...1) < 0.8
            } else {
                // Casualは10%の確率でハイライト
                shouldHighlight = Double.random(in: 0...1) < 0.1
            }
            
            // TranscriptBlockを作成
            let block = TranscriptBlock(
                text: selectedText,
                isHighlighted: shouldHighlight,
                orderIndex: i,
                meeting: meeting
            )
            modelContext.insert(block)
            
            // テキストを結合（改行で区切る）
            transcriptText += selectedText
            if i < blockCount - 1 {
                transcriptText += "\n"
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private static func generateNoteContent() -> String {
        // ノート用のコンテンツを生成（簡易版）
        let noteTemplates = [
            "今日は\(["楽しい", "有意義な", "充実した"].randomElement() ?? "楽しい")時間を過ごしました。",
            "\(["新しい", "興味深い", "重要な"].randomElement() ?? "新しい")話題について話し合いました。",
            "次回は\(["来週", "来月", "近いうちに"].randomElement() ?? "来週")また会う予定です。"
        ]
        return noteTemplates.randomElement() ?? noteTemplates[0]
    }
}

