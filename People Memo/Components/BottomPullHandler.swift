//
//  BottomPullHandler.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI

struct BottomPullHandler: View {
    let onPullUp: () -> Void
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    private let dragThreshold: CGFloat = -80
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // 透明なヒットエリア（タブバーの下）
            Color.clear
                .frame(height: 60)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let translation = value.translation.height
                            
                            // 上方向のドラッグのみ検知
                            if translation < 0 {
                                isDragging = true
                                dragOffset = max(translation, -100) // 最大-100ptまで
                            }
                        }
                        .onEnded { value in
                            let translation = value.translation.height
                            
                            // 閾値を超えたら入力画面を開く
                            if translation < dragThreshold {
                                // 重い触覚フィードバック
                                let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
                                heavyFeedback.impactOccurred()
                                
                                // アクション実行
                                onPullUp()
                            }
                            
                            // リセット
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                dragOffset = 0
                                isDragging = false
                            }
                        }
                )
        }
    }
}

