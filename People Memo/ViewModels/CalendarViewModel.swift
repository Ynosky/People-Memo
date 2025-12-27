//
//  CalendarViewModel.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import Foundation
import SwiftData

@Observable
class CalendarViewModel {
    var selectedDate: Date = Date()
    var currentMonth: Date = Date()
    
    func monthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: currentMonth)
    }
    
    func moveToPreviousMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    func moveToNextMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    func getMeetingsForDate(_ date: Date, meetings: [Meeting]) -> [Meeting] {
        let calendar = Calendar.current
        return meetings.filter { meeting in
            calendar.isDate(meeting.date, inSameDayAs: date)
        }
    }
    
    func getPeopleForDate(_ date: Date, meetings: [Meeting]) -> [Person] {
        let meetingsOnDate = getMeetingsForDate(date, meetings: meetings)
        return meetingsOnDate.compactMap { $0.person }.unique()
    }
}

extension Array where Element: Hashable {
    func unique() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

