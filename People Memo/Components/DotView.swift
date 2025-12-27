//
//  DotView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import UIKit

struct DotView: View {
    let person: Person
    let tagColor: Color
    let size: CGFloat
    let glowIntensity: Double
    
    @State private var isHovered = false
    
    private var personColor: Color {
        Color.personColor(for: person.id)
    }
    
    var body: some View {
        ZStack {
            // グロー効果（最近会った人のみ）
            if glowIntensity > 0.3 {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                tagColor.opacity(glowIntensity * 0.8),
                                tagColor.opacity(glowIntensity * 0.3),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 2
                        )
                    )
                    .frame(width: size * 4, height: size * 4)
                    .blur(radius: size)
            }
            
            // ドット本体
            Circle()
                .fill(tagColor)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                )
                .shadow(color: tagColor.opacity(glowIntensity), radius: size * 0.5, x: 0, y: 0)
        }
        .scaleEffect(isHovered ? 1.5 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
    }
}

#Preview {
    HStack {
        DotView(person: Person(name: "山田太郎", tags: ["Work"]), tagColor: .blue, size: 10, glowIntensity: 0.8)
        DotView(person: Person(name: "佐藤花子", tags: ["Hobby"]), tagColor: .green, size: 10, glowIntensity: 0.3)
        DotView(person: Person(name: "鈴木一郎", tags: ["Family"]), tagColor: .orange, size: 10, glowIntensity: 0.0)
    }
    .padding()
    .background(Color.black)
}

