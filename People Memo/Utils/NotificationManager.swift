//
//  NotificationManager.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // MARK: - Authorization
    
    /// 通知の権限をリクエスト
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("通知権限リクエストエラー: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(granted)
        }
    }
    
    /// 現在の通知権限状態を確認
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            completion(settings.authorizationStatus)
        }
    }
    
    // MARK: - Schedule Notifications
    
    /// 人物に対するリマインダー通知をスケジュール
    func scheduleReminder(for person: Person, date: Date, completion: @escaping (Bool, String?) -> Void) {
        // 通知権限を確認
        checkAuthorizationStatus { status in
            if status != .authorized {
                // 権限がない場合はリクエスト
                self.requestAuthorization { granted in
                    if granted {
                        self.addReminderNotification(for: person, date: date, completion: completion)
                    } else {
                        completion(false, "通知の権限が許可されていません。設定アプリから通知を有効にしてください。")
                    }
                }
            } else {
                self.addReminderNotification(for: person, date: date, completion: completion)
            }
        }
    }
    
    private func addReminderNotification(for person: Person, date: Date, completion: @escaping (Bool, String?) -> Void) {
        // 過去の日付の場合はスケジュールしない
        if date < Date() {
            completion(false, "過去の日付にはリマインダーを設定できません。")
            return
        }
        
        // 既存の通知を削除（同じ人物の通知を上書き）
        let identifier = "person_reminder_\(person.id.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        
        // 通知コンテンツを作成
        let content = UNMutableNotificationContent()
        content.title = "\(person.name)さんとの約束"
        content.body = "今日は\(person.name)さんと会う予定です。"
        content.sound = .default
        content.badge = 1
        
        // 通知をカテゴリ化（将来的にアクションを追加する場合に備えて）
        content.categoryIdentifier = "PERSON_REMINDER"
        
        // 日時コンポーネントを取得
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        // トリガーを作成
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // リクエストを作成
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // 通知をスケジュール
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知スケジュールエラー: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
        }
    }
    
    // MARK: - Cancel Notifications
    
    /// 人物のリマインダー通知をキャンセル
    func cancelReminder(for person: Person) {
        let identifier = "person_reminder_\(person.id.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    /// すべてのリマインダー通知をキャンセル
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

