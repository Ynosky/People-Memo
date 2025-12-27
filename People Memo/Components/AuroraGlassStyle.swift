//
//  AuroraGlassStyle.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI

struct AuroraGlassStyle: ViewModifier {
    var cornerRadius: CGFloat = 24
    var accentColor: Color = .white
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.black.opacity(0.6)) // 濃い半透明の黒（Material削除）
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                accentColor,
                                accentColor.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5 // 太いネオンボーダー
                    )
                    .shadow(color: accentColor.opacity(0.8), radius: 4, x: 0, y: 0)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func auroraGlass(
        cornerRadius: CGFloat = 24,
        accentColor: Color = .white
    ) -> some View {
        self.modifier(AuroraGlassStyle(
            cornerRadius: cornerRadius,
            accentColor: accentColor
        ))
    }
}

