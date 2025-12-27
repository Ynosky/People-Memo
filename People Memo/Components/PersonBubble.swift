//
//  PersonBubble.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import UIKit

struct PersonBubble: View {
    let person: Person
    var size: CGFloat = 60
    var showBorder: Bool = true
    var borderWidth: CGFloat = 4
    
    private var personColor: Color {
        Color.personColor(for: person.id)
    }
    
    var body: some View {
        ZStack {
            // 背景の有機的な形（Blob shape）
            RoundedRectangle(cornerRadius: size * 0.4)
                .fill(personColor.opacity(0.2))
                .frame(width: size, height: size)
            
            // アイコンまたはイニシャル
            if let imageData = person.iconImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size * 0.7, height: size * 0.7)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(personColor)
                    .frame(width: size * 0.7, height: size * 0.7)
                    .overlay(
                        Text(person.initials)
                            .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    )
            }
            
            // 太いカラフルな枠線
            if showBorder {
                RoundedRectangle(cornerRadius: size * 0.4)
                    .stroke(personColor, lineWidth: borderWidth)
                    .frame(width: size, height: size)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack {
        PersonBubble(person: Person(name: "山田太郎"), size: 80)
        PersonBubble(person: Person(name: "佐藤花子"), size: 80)
        PersonBubble(person: Person(name: "鈴木一郎"), size: 80)
    }
    .padding()
    .background(Color.white)
}

