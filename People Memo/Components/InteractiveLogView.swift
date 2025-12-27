//
//  InteractiveLogView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI

struct InteractiveLogView: View {
    @Binding var text: String
    @Binding var highlightedTexts: Set<String>
    @Environment(\.colorScheme) var colorScheme
    
    // テキストをブロックに分割（改行または句点で分割）
    private var textBlocks: [String] {
        // まず改行で分割
        let lines = text.components(separatedBy: .newlines)
        
        var blocks: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // 空行の場合はスキップ
            if trimmedLine.isEmpty {
                continue
            }
            
            // 句点（。または.）で分割
            // 日本語の句点を優先
            if trimmedLine.contains("。") {
                let sentences = trimmedLine.components(separatedBy: "。")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                
                for (index, sentence) in sentences.enumerated() {
                    let block = sentence + (index < sentences.count - 1 ? "。" : "")
                    blocks.append(block)
                }
            } else if trimmedLine.contains(".") {
                // 英語のピリオドで分割
                let sentences = trimmedLine.components(separatedBy: ".")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                
                for (index, sentence) in sentences.enumerated() {
                    let block = sentence + (index < sentences.count - 1 ? "." : "")
                    blocks.append(block)
                }
            } else {
                // 句点がない場合は行全体を1ブロックとして扱う
                blocks.append(trimmedLine)
            }
        }
        
        // ブロックが空の場合は元のテキストをそのまま返す
        return blocks.isEmpty ? [text] : blocks
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(textBlocks.enumerated()), id: \.offset) { index, block in
                    TextBlockView(
                        text: block,
                        isHighlighted: highlightedTexts.contains(block),
                        colorScheme: colorScheme
                    ) {
                        // タップでハイライトをトグル
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if highlightedTexts.contains(block) {
                                highlightedTexts.remove(block)
                            } else {
                                highlightedTexts.insert(block)
                            }
                        }
                        
                        // 触覚フィードバック
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

struct TextBlockView: View {
    let text: String
    let isHighlighted: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundColor(Color.primaryText(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHighlighted ? Color.brandPrimary.opacity(0.15) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    isHighlighted ? Color.brandPrimary : Color.clear,
                                    lineWidth: isHighlighted ? 2 : 0
                                )
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var text = "今日は良い天気でした。公園で散歩をしました。とても楽しかったです。"
        @State private var highlightedTexts: Set<String> = []
        
        var body: some View {
            InteractiveLogView(
                text: $text,
                highlightedTexts: $highlightedTexts
            )
        }
    }
    
    return PreviewWrapper()
}

