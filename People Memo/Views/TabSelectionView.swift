//
//  TabSelectionView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI

struct TabSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Tab
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button(action: {
                        let selectionFeedback = UISelectionFeedbackGenerator()
                        selectionFeedback.selectionChanged()
                        
                        selectedTab = tab
                        dismiss()
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: .medium, design: .rounded))
                                .foregroundColor(selectedTab == tab ? .brandPrimary : .secondary)
                                .frame(width: 32)
                            
                            Text(tab.rawValue)
                                .font(.system(size: 17, weight: selectedTab == tab ? .semibold : .regular, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedTab == tab {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.brandPrimary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("ビューを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

