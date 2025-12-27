//
//  CalendarView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meeting.date, order: .reverse) private var meetings: [Meeting]
    @State private var viewModel = CalendarViewModel()
    @State private var selectedMeeting: Meeting?
    @State private var showingWeeklyPlanner = false
    @Environment(\.colorScheme) var colorScheme
    
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 月のヘッダー
                        HStack {
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                viewModel.moveToPreviousMonth()
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Color.primaryText(for: colorScheme))
                        }
                        
                        Spacer()
                        
                        Text(viewModel.monthYearString())
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color.primaryText(for: colorScheme))
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                viewModel.moveToNextMonth()
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Color.primaryText(for: colorScheme))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // 曜日ヘッダー
                    HStack(spacing: 0) {
                        ForEach(weekdayIndices, id: \.self) { index in
                            Text(weekdayString(for: index))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    
                    // カレンダーグリッド（バブルスタイル）
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 12) {
                        ForEach(daysInMonth, id: \.self) { date in
                            if let date = date {
                                CalendarBubbleCell(
                                    date: date,
                                    meetings: viewModel.getMeetingsForDate(date, meetings: meetings),
                                    people: viewModel.getPeopleForDate(date, meetings: meetings),
                                    isToday: calendar.isDateInToday(date),
                                    isCurrentMonth: calendar.isDate(date, equalTo: viewModel.currentMonth, toGranularity: .month)
                                )
                                .onTapGesture {
                                    let meetingsOnDate = viewModel.getMeetingsForDate(date, meetings: meetings)
                                    if let firstMeeting = meetingsOnDate.first {
                                        selectedMeeting = firstMeeting
                                    }
                                }
                            } else {
                                Color.clear
                                    .frame(height: 70)
                            }
                        }
                    }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 100) // FloatingTabBarのスペース
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("カレンダー")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color.primaryText(for: colorScheme))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingWeeklyPlanner = true }) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color.primaryText(for: colorScheme))
                    }
                }
            }
            .sheet(item: $selectedMeeting) { meeting in
                MeetingDetailView(meeting: meeting)
            }
            .sheet(isPresented: $showingWeeklyPlanner) {
                WeeklyPlannerView()
            }
        }
    }
    
    private var weekdayIndices: [Int] {
        [0, 1, 2, 3, 4, 5, 6] // 日曜日から土曜日
    }
    
    private func weekdayString(for index: Int) -> String {
        let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
        return weekdays[index]
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: viewModel.currentMonth),
              let firstDayOfMonth = calendar.dateInterval(of: .month, for: viewModel.currentMonth)?.start else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        let daysInMonth = calendar.range(of: .day, in: .month, for: viewModel.currentMonth)?.count ?? 0
        
        var days: [Date?] = []
        
        // 前月の空白セル
        for _ in 0..<firstWeekday {
            days.append(nil)
        }
        
        // 今月の日付
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
}

struct CalendarBubbleCell: View {
    let date: Date
    let meetings: [Meeting]
    let people: [Person]
    let isToday: Bool
    let isCurrentMonth: Bool
    @Environment(\.colorScheme) var colorScheme
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 日付セル
            VStack(spacing: 0) {
                Text(dateFormatter.string(from: date))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(isCurrentMonth ? Color.primaryText(for: colorScheme) : .secondary.opacity(0.4))
            }
            .frame(width: 50, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isToday ? Color.brandPrimary.opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isToday ? Color.brandPrimary : Color.primary.opacity(0.1), lineWidth: isToday ? 2 : 0.5)
            )
            
            // 人物アイコン（はみ出すように配置）
            if !people.isEmpty {
                HStack(spacing: -8) {
                    // 最初の1人を表示
                    if let firstPerson = people.first {
                        PersonBubble(person: firstPerson, size: 28, borderWidth: 1.5)
                            .offset(x: 0, y: -8)
                    }
                    
                    // 2人以上の場合、残り人数を表示
                    if people.count > 1 {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 28, height: 28)
                            
                            Text("+\(people.count - 1)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(Color.primaryText(for: colorScheme))
                        }
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                        .offset(x: 0, y: -8)
                    }
                }
                .offset(x: 8, y: -8)
            }
        }
        .frame(height: 60)
        .opacity(isCurrentMonth ? 1.0 : 0.4)
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [Person.self, Meeting.self, Note.self, TranscriptBlock.self, AgendaItem.self], inMemory: true)
}
