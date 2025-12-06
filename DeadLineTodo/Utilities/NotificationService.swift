//
//  NotificationService.swift
//  DeadLineTodo
//
//  Handles local notifications
//

import Foundation
import UserNotifications

final class NotificationService {
    
    static let shared = NotificationService()
    private init() {}
    
    // MARK: - Send Notifications
    
    /// 发送所有相关通知
    func sendNotifications(for todo: TodoData) {
        sendDeadlineNotification(for: todo)
        sendExpiredNotification(for: todo)
        sendEmergencyNotification(for: todo)
    }
    
    /// 发送将截止通知
    func sendDeadlineNotification(for todo: TodoData) {
        let leftTime = getLeftTime(for: todo)
        guard leftTime > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("将截止", comment: "")
        content.subtitle = todo.content
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: leftTime, repeats: false)
        let request = UNNotificationRequest(
            identifier: todo.id.uuidString + "1",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// 发送已截止通知
    func sendExpiredNotification(for todo: TodoData) {
        let leftTime = getLeftTime(for: todo)
        let needTime = TimeInterval.from(days: todo.Day, hours: todo.Hour, minutes: todo.Min)
        let totalTime = leftTime + needTime
        
        guard totalTime > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("已截止", comment: "")
        content.subtitle = todo.content
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: totalTime, repeats: false)
        let request = UNNotificationRequest(
            identifier: todo.id.uuidString + "2",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// 发送紧急通知
    func sendEmergencyNotification(for todo: TodoData) {
        let interval = todo.emergencyDate.timeIntervalSince1970 - Date().timeIntervalSince1970
        guard interval > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("紧急！", comment: "")
        content.subtitle = todo.content
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: todo.id.uuidString + "3",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// 发送任务超时通知
    func sendOvertimeNotification(for todo: TodoData) {
        let interval = todo.needTime - todo.lastTime
        guard interval > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("任务超时", comment: "")
        content.subtitle = todo.content
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: todo.id.uuidString + "4",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Cancel Notifications
    
    /// 取消单个通知
    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    /// 取消任务的所有通知
    func cancelAllNotifications(for todo: TodoData) {
        let ids = (1...4).map { todo.id.uuidString + "\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
    
    // MARK: - Helper
    
    private func getLeftTime(for todo: TodoData) -> TimeInterval {
        let needTime = TimeInterval.from(days: todo.Day, hours: todo.Hour, minutes: todo.Min, seconds: todo.Sec)
        return todo.endDate.timeIntervalSince1970 - Date().timeIntervalSince1970 - needTime
    }
    
    // MARK: - Permission
    
    /// 请求通知权限
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print("通知权限请求失败: \(error.localizedDescription)")
            }
        }
    }
}
