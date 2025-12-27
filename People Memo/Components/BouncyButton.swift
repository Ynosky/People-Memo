//
//  BouncyButton.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI

struct BouncyButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Haptic Feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            
            action()
        }) {
            label()
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Convenience Initializers

extension BouncyButton where Label == Text {
    init(_ title: String, action: @escaping () -> Void) {
        self.action = action
        self.label = { Text(title) }
    }
}

// MARK: - Style Modifier

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension Button {
    func bouncy() -> some View {
        self.buttonStyle(BouncyButtonStyle())
            .onTapGesture {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
    }
}

