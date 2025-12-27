//
//  FloatingTabBar.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI

enum Tab: String, CaseIterable {
    case home = "ホーム"
    case review = "振り返り"
    case people = "人物"
    case calendar = "カレンダー"
    case galaxy = "Galaxy"
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .review: return "rectangle.stack"
        case .people: return "person.2"
        case .calendar: return "calendar"
        case .galaxy: return "sparkles"
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selectedTab: Tab
    @State private var bounceScale: [Tab: CGFloat] = [:]
    @State private var handlePulse = false
    
    var body: some View {
        VStack(spacing: 0) {
            // ハンドルバー（視覚的ヒント）
            VStack(spacing: 4) {
                Capsule()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 36, height: 4)
                    .scaleEffect(handlePulse ? 1.1 : 1.0)
                    .opacity(handlePulse ? 0.6 : 0.3)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: handlePulse)
                
                Text("上に引っ張る")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.bottom, 8)
            
            // タブバー
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedTab = tab
                            bounceScale[tab] = 1.2
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                bounceScale[tab] = 1.0
                            }
                        }
                    }) {
                        ZStack {
                            // 選択中の背景（ふんわりとした光）
                            if selectedTab == tab {
                                Circle()
                                    .fill(Color.brandPrimary.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                    .blur(radius: 8)
                            }
                            
                            // アイコン
                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: .medium, design: .rounded))
                                .foregroundColor(selectedTab == tab ? .brandPrimary : .secondary)
                                .scaleEffect(bounceScale[tab] ?? 1.0)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
        .onAppear {
            handlePulse = true
        }
    }
}

