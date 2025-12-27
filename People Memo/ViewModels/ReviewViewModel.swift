//
//  ReviewViewModel.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import Foundation
import SwiftData

@Observable
class ReviewViewModel {
    var currentBlockIndex: Int = 0
    var blocksToReview: [TranscriptBlock] = []
    
    func loadReviewBlocks(blocks: [TranscriptBlock]) {
        // ハイライトされたブロックをフィルタリング
        let highlightedBlocks = blocks.filter { $0.isHighlighted }
        
        // ランダムにシャッフル（最初の20件）
        blocksToReview = Array(highlightedBlocks.shuffled().prefix(20))
        currentBlockIndex = 0
    }
    
    var currentBlock: TranscriptBlock? {
        guard currentBlockIndex < blocksToReview.count else { return nil }
        return blocksToReview[currentBlockIndex]
    }
    
    var hasMoreBlocks: Bool {
        currentBlockIndex < blocksToReview.count - 1
    }
    
    func moveToNext() {
        if hasMoreBlocks {
            currentBlockIndex += 1
        }
    }
}
