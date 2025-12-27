//
//  TagFilterBar.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData

struct TagFilterBar: View {
    @Binding var selectedTag: String?
    @Query(sort: \Person.createdAt) private var allPeople: [Person]
    @Environment(\.colorScheme) var colorScheme
    
    // 全人物からユニークなタグを抽出
    private var uniqueTags: [String] {
        let allTags = allPeople.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // "All" ボタン
                TagCapsuleButton(
                    title: "All",
                    isSelected: selectedTag == nil,
                    colorScheme: colorScheme
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTag = nil
                    }
                    
                    // 触覚フィードバック
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
                
                // 動的タグボタン
                ForEach(uniqueTags, id: \.self) { tag in
                    TagCapsuleButton(
                        title: tag,
                        isSelected: selectedTag == tag,
                        colorScheme: colorScheme
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTag = tag
                        }
                        
                        // 触覚フィードバック
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
}

struct TagCapsuleButton: View {
    let title: String
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : Color.primaryText(for: colorScheme))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.brandPrimary : Color.clear)
                        .overlay(
                            Capsule()
                                .stroke(
                                    isSelected ? Color.brandPrimary : Color.cardBorder(for: colorScheme),
                                    lineWidth: isSelected ? 0 : 1
                                )
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTag: String? = nil
        
        var body: some View {
            VStack {
                TagFilterBar(selectedTag: $selectedTag)
                    .padding(.top, 20)
                Spacer()
            }
        }
    }
    
    return PreviewWrapper()
        .modelContainer(for: [Person.self], inMemory: true)
}

