//
//  TooltipOverlay.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import UIKit

struct TooltipOverlay: View {
    let people: [Person]
    let positions: [UUID: CGPoint]
    let tagColorForPerson: (Person) -> Color
    
    @State private var dragLocation: CGPoint?
    @State private var hoveredPerson: Person?
    @State private var lastHoveredId: UUID?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 透明なドラッグ検知エリア
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                dragLocation = value.location
                                updateHoveredPerson(at: value.location, in: geometry.size)
                            }
                            .onEnded { _ in
                                dragLocation = nil
                                hoveredPerson = nil
                                lastHoveredId = nil
                            }
                    )
                
                // ツールチップ
                if let person = hoveredPerson,
                   let position = positions[person.id] {
                    TooltipView(person: person, tagColor: tagColorForPerson(person))
                        .position(
                            x: position.x,
                            y: position.y - 40
                        )
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
    
    private func updateHoveredPerson(at location: CGPoint, in size: CGSize) {
        let threshold: CGFloat = 30 // ドット検知範囲
        
        var closestPerson: Person?
        var closestDistance: CGFloat = CGFloat.infinity
        
        for (personId, position) in positions {
            let distance = sqrt(
                pow(location.x - position.x, 2) +
                pow(location.y - position.y, 2)
            )
            
            if distance < threshold && distance < closestDistance {
                closestDistance = distance
                if let person = people.first(where: { $0.id == personId }) {
                    closestPerson = person
                }
            }
        }
        
        if let person = closestPerson, person.id != lastHoveredId {
            // Haptic Feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                hoveredPerson = person
                lastHoveredId = person.id
            }
        } else if closestPerson == nil {
            hoveredPerson = nil
            lastHoveredId = nil
        }
    }
}

struct TooltipView: View {
    // DTOパターン：Personオブジェクトではなく、必要な情報だけを受け取る
    let personName: String
    let initials: String
    let tag: String
    let tagColor: Color
    let iconImageData: Data?
    let personId: UUID?
    
    // 既存のコードとの互換性のため、Personオブジェクトを受け取るイニシャライザも提供
    init(person: Person, tagColor: Color) {
        self.personName = person.name
        self.initials = person.initials
        self.tag = person.tags.first ?? ""
        self.tagColor = tagColor
        self.iconImageData = person.iconImageData
        self.personId = person.id
    }
    
    // DTOパターン用のイニシャライザ
    init(personName: String, initials: String, tag: String, tagColor: Color, iconImageData: Data?) {
        self.personName = personName
        self.initials = initials
        self.tag = tag
        self.tagColor = tagColor
        self.iconImageData = iconImageData
        self.personId = nil
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // 小さな顔アイコン
            if let imageData = iconImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(personId.map { Color.personColor(for: $0) } ?? tagColor)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text(initials)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    )
            }
            
            // 名前
            Text(personName)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white) // ライトモード：白背景なので文字は白
            
            // タグバッジ
            if !tag.isEmpty {
                Text(tag)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(tagColor)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemGray6)) // ライトモード：濃いグレー背景
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    TooltipView(
        person: Person(name: "山田太郎", tags: ["Work"]),
        tagColor: .blue
    )
    .padding()
    .background(Color.gray.opacity(0.2))
}

