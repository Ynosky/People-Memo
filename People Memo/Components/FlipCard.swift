//
//  FlipCard.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI

struct FlipCard<Front: View, Back: View>: View {
    let front: () -> Front
    let back: () -> Back
    
    @State private var isFlipped = false
    
    var body: some View {
        ZStack {
            // 表面
            front()
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
            
            // 裏面
            back()
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
            
            // Haptic Feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - Convenience Initializer

extension FlipCard where Front == AnyView, Back == AnyView {
    init<F: View, B: View>(@ViewBuilder front: @escaping () -> F, @ViewBuilder back: @escaping () -> B) {
        self.front = { AnyView(front()) }
        self.back = { AnyView(back()) }
    }
}

#Preview {
    FlipCard {
        VStack {
            Text("表面")
                .font(.title)
            Text("タップして裏面を見る")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 200, height: 300)
        .background(Color.blue.opacity(0.2))
        .cornerRadius(20)
    } back: {
        VStack {
            Text("裏面")
                .font(.title)
            Text("メモや答えが表示されます")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 200, height: 300)
        .background(Color.green.opacity(0.2))
        .cornerRadius(20)
    }
}

