//
//  AuroraBackground.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI

struct AuroraBackground: View {
    var body: some View {
        // 静的なグラデーション背景（軽量化）
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "050510"), // 深い紺色（ほぼ黒）
                Color(hex: "0A0A1A")  // やや明るい深い紫
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

