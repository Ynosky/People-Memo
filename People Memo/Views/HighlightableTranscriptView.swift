//
//  HighlightableTranscriptView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData

struct HighlightableTranscriptView: View {
    @Environment(\.modelContext) private var modelContext
    let meeting: Meeting
    @State private var blocks: [TranscriptBlock] = []
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if blocks.isEmpty {
                    Text("まだ対談ログがありません")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(blocks.sorted(by: { $0.orderIndex < $1.orderIndex }), id: \.id) { block in
                        TranscriptBlockRow(block: block)
                            .onTapGesture {
                                toggleHighlight(for: block)
                            }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            loadBlocks()
        }
    }
    
    private func loadBlocks() {
        blocks = meeting.transcriptBlocks ?? []
    }
    
    private func toggleHighlight(for block: TranscriptBlock) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            block.isHighlighted.toggle()
        }
    }
}

struct TranscriptBlockRow: View {
    let block: TranscriptBlock
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // ハイライトインジケーター
            Circle()
                .fill(block.isHighlighted ? Color.yellow : Color.clear)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(block.isHighlighted ? Color.yellow : Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.top, 6)
            
            // テキスト
            Text(block.text.isEmpty ? " " : block.text)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(block.isHighlighted ? Color.yellow.opacity(0.3) : Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(block.isHighlighted ? Color.yellow.opacity(0.5) : Color.clear, lineWidth: 2)
                )
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Meeting.self, TranscriptBlock.self, configurations: config)
    let meeting = Meeting(date: Date())
    
    return HighlightableTranscriptView(meeting: meeting)
        .modelContainer(container)
}

