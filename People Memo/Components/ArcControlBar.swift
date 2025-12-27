//
//  ArcControlBar.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI

struct ArcControlBar: View {
    @Binding var selectedTab: Tab
    let onNewNote: () -> Void
    let onShowTabs: () -> Void
    let onShowSettings: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isPressed = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    private let dragThreshold: CGFloat = -80
    
    private var borderColor: Color {
        switch colorScheme {
        case .light:
            return Color.white.opacity(0.2)
        case .dark:
            return Color.white.opacity(0.15) // ダークモードではより繊細に
        @unknown default:
            return Color.white.opacity(0.2)
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Left: Tab Switcher
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                onShowTabs()
            }) {
                Image(systemName: "square.on.square")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            
            // Center: New Input Button
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                    onNewNote()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text("New Note")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primary.opacity(0.05))
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let translation = value.translation.height
                        
                        if translation < 0 {
                            isDragging = true
                            dragOffset = max(translation, -100)
                        }
                    }
                    .onEnded { value in
                        let translation = value.translation.height
                        
                        if translation < dragThreshold {
                            let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
                            heavyFeedback.impactOccurred()
                            onNewNote()
                        }
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = 0
                            isDragging = false
                        }
                    }
            )
            
            // Right: Settings
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                onShowSettings()
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.thinMaterial) // ダークモードで黒を透過させる
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(borderColor, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .offset(y: dragOffset)
        .opacity(isDragging ? 0.8 : 1.0)
    }
}

