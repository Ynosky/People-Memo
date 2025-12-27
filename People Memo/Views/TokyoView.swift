//
//  TokyoView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData

struct TokyoView: View {
    @Query(sort: \Person.createdAt, order: .reverse) private var people: [Person]
    @Query(sort: \Meeting.date, order: .reverse) private var allMeetings: [Meeting]
    @Query(sort: \Note.createdAt, order: .reverse) private var allNotes: [Note]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 上部 35%: Galaxy View
                ZStack {
                    // 深い黒背景
                    Color(hex: "000000")
                        .ignoresSafeArea(edges: .top)
                    
                    // Galaxy View（背景を透明にして親の黒背景を使用）
                    CompactGalaxyView()
                        .frame(height: geometry.size.height * 0.35)
                        .clipShape(Rectangle())
                }
                .frame(height: geometry.size.height * 0.35)
                
                // セパレータ
                Divider()
                    .background(Color.cardBorder(for: colorScheme))
                
                // 下部 65%: Statistics Grid
                ScrollView(.vertical, showsIndicators: false) {
                    StatisticsGrid(
                        people: people,
                        meetings: allMeetings,
                        notes: allNotes,
                        colorScheme: colorScheme
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .padding(.bottom, 100) // Arc Control Barのスペース
                }
                .frame(height: geometry.size.height * 0.65)
                .background(Color.appBackground(for: colorScheme))
            }
        }
        .background(Color.appBackground(for: colorScheme))
    }
}

#Preview {
    TokyoView()
        .modelContainer(for: [Person.self, Meeting.self, Note.self, TranscriptBlock.self, AgendaItem.self], inMemory: true)
}

