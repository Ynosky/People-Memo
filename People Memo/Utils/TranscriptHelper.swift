//
//  TranscriptHelper.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import Foundation
import SwiftData

class TranscriptHelper {
    /// 文字列を改行で分割し、TranscriptBlockの配列に変換
    static func createBlocks(from text: String, meeting: Meeting, modelContext: ModelContext) -> [TranscriptBlock] {
        // 改行で分割（空行も含める）
        let lines = text.components(separatedBy: .newlines)
        
        var blocks: [TranscriptBlock] = []
        
        for (index, line) in lines.enumerated() {
            // 空行はスキップしない（視覚的な区切りとして保持）
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            let block = TranscriptBlock(
                text: trimmedLine.isEmpty ? " " : line, // 空行の場合はスペース1つを保持
                isHighlighted: false,
                orderIndex: index,
                meeting: meeting
            )
            modelContext.insert(block)
            blocks.append(block)
        }
        
        return blocks
    }
    
    /// 既存のTranscriptBlockを更新（テキストを再分割）
    static func updateBlocks(from text: String, meeting: Meeting, modelContext: ModelContext) {
        // 既存のブロックを削除
        if let existingBlocks = meeting.transcriptBlocks {
            for block in existingBlocks {
                modelContext.delete(block)
            }
        }
        
        // 新しいブロックを作成
        let newBlocks = createBlocks(from: text, meeting: meeting, modelContext: modelContext)
        meeting.transcriptBlocks = newBlocks
    }
    
    /// TranscriptBlockの配列からテキストを再構築
    static func reconstructText(from blocks: [TranscriptBlock]) -> String {
        return blocks.sorted { $0.orderIndex < $1.orderIndex }
            .map { $0.text }
            .joined(separator: "\n")
    }
}

