//
//  CardModifier.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI

struct CardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 24
    var shadowColor: Color = Color.black.opacity(0.1)
    var shadowRadius: CGFloat = 10
    var shadowY: CGFloat = 5
    var backgroundColor: Color? = nil
    
    func body(content: Content) -> some View {
        let bgColor = backgroundColor ?? Color.cardBackground(for: colorScheme)
        content
            .background(bgColor)
            .cornerRadius(cornerRadius)
            .shadow(color: colorScheme == .dark ? Color.clear : shadowColor, radius: shadowRadius, x: 0, y: shadowY)
    }
}

extension View {
    func cardStyle(
        cornerRadius: CGFloat = 24,
        shadowColor: Color = Color.black.opacity(0.1),
        shadowRadius: CGFloat = 10,
        shadowY: CGFloat = 5,
        backgroundColor: Color? = nil
    ) -> some View {
        self.modifier(CardModifier(
            cornerRadius: cornerRadius,
            shadowColor: shadowColor,
            shadowRadius: shadowRadius,
            shadowY: shadowY,
            backgroundColor: backgroundColor
        ))
    }
}

