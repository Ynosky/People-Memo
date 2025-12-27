//
//  StatisticsGrid.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData
import Charts

struct StatisticsGrid: View {
    let people: [Person]
    let meetings: [Meeting]
    let notes: [Note]
    let colorScheme: ColorScheme
    
    // 統計データの計算
    private var totalMeetings: Int {
        meetings.filter { !$0.isFuture }.count
    }
    
    private var thisMonthNotes: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        return notes.filter { $0.createdAt >= startOfMonth }.count
    }
    
    private var totalPeople: Int {
        people.count
    }
    
    // 過去30日間の活動量（日別のNote数）
    private var activityData: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let now = Date()
        var data: [(date: Date, count: Int)] = []
        
        for i in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let count = notes.filter { note in
                note.createdAt >= startOfDay && note.createdAt < endOfDay
            }.count
            
            data.append((date: startOfDay, count: count))
        }
        
        return data.reversed()
    }
    
    // よく会う人ランキング（Meeting数が多い順）
    private var topConnections: [(person: Person, count: Int)] {
        var personMeetingCounts: [UUID: Int] = [:]
        
        for meeting in meetings.filter({ !$0.isFuture }) {
            if let personId = meeting.person?.id {
                personMeetingCounts[personId, default: 0] += 1
            }
        }
        
        return personMeetingCounts.compactMap { (personId, count) in
            guard let person = people.first(where: { $0.id == personId }) else { return nil }
            return (person: person, count: count)
        }
        .sorted { $0.count > $1.count }
        .prefix(3)
        .map { $0 }
    }
    
    // 疎遠な人（90日以上会っていない）
    private var neglectedPeople: [Person] {
        people.filter { person in
            if let days = person.daysSinceLastMeeting {
                return days >= 90
            }
            // 会ったことがない人も含める
            return person.meetings?.isEmpty ?? true
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Summary Row (Small Cards)
            HStack(spacing: 12) {
                SummaryCard(
                    title: "総対話数",
                    value: "\(totalMeetings)",
                    icon: "bubble.left.and.bubble.right.fill",
                    colorScheme: colorScheme
                )
                
                SummaryCard(
                    title: "今月の記録",
                    value: "\(thisMonthNotes)",
                    icon: "note.text",
                    colorScheme: colorScheme
                )
                
                SummaryCard(
                    title: "登録人数",
                    value: "\(totalPeople)",
                    icon: "person.2.fill",
                    colorScheme: colorScheme
                )
            }
            
            // Trend Chart (Medium Card)
            TrendChartCard(
                data: activityData,
                colorScheme: colorScheme
            )
            
            // Top Connections (List Card)
            TopConnectionsCard(
                connections: topConnections,
                colorScheme: colorScheme
            )
            
            // Neglected Alert (Warning Card)
            if !neglectedPeople.isEmpty {
                NeglectedAlertCard(
                    people: neglectedPeople,
                    count: neglectedPeople.count,
                    colorScheme: colorScheme
                )
            }
        }
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.brandPrimary)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color.primaryText(for: colorScheme))
            
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cardBorder(for: colorScheme), lineWidth: 1)
                )
        )
    }
}

// MARK: - Trend Chart Card

struct TrendChartCard: View {
    let data: [(date: Date, count: Int)]
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("過去30日間の活動")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color.primaryText(for: colorScheme))
                
                Spacer()
            }
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                        BarMark(
                            x: .value("日", index),
                            y: .value("記録数", item.count)
                        )
                        .foregroundStyle(Color.brandPrimary)
                        .cornerRadius(4)
                    }
                }
                .frame(height: 150)
                .chartXAxis {
                    AxisMarks(values: .stride(by: 5)) { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.secondary.opacity(0.2))
                        AxisValueLabel()
                            .foregroundStyle(Color.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.secondary.opacity(0.2))
                        AxisValueLabel()
                            .foregroundStyle(Color.secondary)
                    }
                }
            } else {
                // iOS 16未満のフォールバック
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                        HStack(spacing: 8) {
                            Text("\(index + 1)日目")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .leading)
                            
                            GeometryReader { geometry in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.brandPrimary)
                                    .frame(width: max(2, geometry.size.width * CGFloat(item.count) / CGFloat(max(data.map { $0.count }.max() ?? 1, 1))))
                            }
                            .frame(height: 8)
                            
                            Text("\(item.count)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
                .frame(height: 150)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cardBorder(for: colorScheme), lineWidth: 1)
                )
        )
    }
}

// MARK: - Top Connections Card

struct TopConnectionsCard: View {
    let connections: [(person: Person, count: Int)]
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("よく会う人")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color.primaryText(for: colorScheme))
                
                Spacer()
            }
            
            if connections.isEmpty {
                Text("データがありません")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(connections.enumerated()), id: \.element.person.id) { index, connection in
                        HStack(spacing: 12) {
                            // ランキング番号
                            Text("\(index + 1)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.brandPrimary)
                                .frame(width: 24)
                            
                            // アバター
                            PersonBubble(person: connection.person, size: 40, borderWidth: 2)
                            
                            // 名前
                            Text(connection.person.name)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(Color.primaryText(for: colorScheme))
                            
                            Spacer()
                            
                            // 回数
                            Text("\(connection.count)回")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        
                        if index < connections.count - 1 {
                            Divider()
                                .background(Color.cardBorder(for: colorScheme))
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cardBorder(for: colorScheme), lineWidth: 1)
                )
        )
    }
}

// MARK: - Neglected Alert Card

struct NeglectedAlertCard: View {
    let people: [Person]
    let count: Int
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.brandSecondary)
                
                Text("疎遠な人")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color.primaryText(for: colorScheme))
                
                Spacer()
            }
            
            Text("\(count)人が90日以上会っていません")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
            
            // 疎遠な人のリスト（最大3人）
            VStack(spacing: 8) {
                ForEach(Array(people.prefix(3)), id: \.id) { person in
                    HStack(spacing: 12) {
                        PersonBubble(person: person, size: 32, borderWidth: 1)
                        
                        Text(person.name)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Color.primaryText(for: colorScheme))
                        
                        Spacer()
                        
                        if let days = person.daysSinceLastMeeting {
                            Text("\(days)日前")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.brandSecondary)
                        } else {
                            Text("未記録")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.brandSecondary)
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.brandSecondary.opacity(0.3), lineWidth: 1.5)
                )
        )
    }
}

