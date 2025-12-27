//
//  MainTabView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @State private var previousTab: Tab = .home
    @State private var showingAddModal = false
    @State private var showingTabSelection = false
    @State private var showingSettings = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // アダプティブ背景（セマンティック色）
            Color.appBackground(for: colorScheme)
                .ignoresSafeArea()
            
            // コンテンツ（横スライドアニメーション）
            ZStack {
                ForEach(Tab.allCases, id: \.self) { tab in
                    if tab == selectedTab {
                        tabView(for: tab)
                            .transition(.asymmetric(
                                insertion: .move(edge: getInsertionEdge()),
                                removal: .move(edge: getRemovalEdge())
                            ))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedTab)
            
            // Arc Style Control Bar
            VStack {
                Spacer()
                ArcControlBar(
                    selectedTab: $selectedTab,
                    onNewNote: {
                        showingAddModal = true
                    },
                    onShowTabs: {
                        showingTabSelection = true
                    },
                    onShowSettings: {
                        showingSettings = true
                    }
                )
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showingAddModal) {
            LogInteractionView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingTabSelection) {
            TabSelectionView(selectedTab: $selectedTab)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            previousTab = oldValue
        }
        .onAppear {
            // ナビゲーションバーのスタイル
            let navAppearance = UINavigationBarAppearance()
            navAppearance.configureWithOpaqueBackground()
            navAppearance.backgroundColor = UIColor.systemBackground
            navAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
            
            UINavigationBar.appearance().standardAppearance = navAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
            UINavigationBar.appearance().compactAppearance = navAppearance
        }
    }
    
    @ViewBuilder
    private func tabView(for tab: Tab) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .review:
            ReviewView()
        case .people:
            PersonListView()
        case .calendar:
            CalendarView()
        }
    }
    
    private func getInsertionEdge() -> Edge {
        let currentIndex = Tab.allCases.firstIndex(of: selectedTab) ?? 0
        let previousIndex = Tab.allCases.firstIndex(of: previousTab) ?? 0
        
        if currentIndex > previousIndex {
            return .trailing // 右から入場
        } else {
            return .leading // 左から入場
        }
    }
    
    private func getRemovalEdge() -> Edge {
        let currentIndex = Tab.allCases.firstIndex(of: selectedTab) ?? 0
        let previousIndex = Tab.allCases.firstIndex(of: previousTab) ?? 0
        
        if currentIndex > previousIndex {
            return .leading // 左へ退場
        } else {
            return .trailing // 右へ退場
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Person.self, Meeting.self, Note.self, TranscriptBlock.self, AgendaItem.self], inMemory: true)
}
