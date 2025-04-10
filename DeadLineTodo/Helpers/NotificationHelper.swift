//
//  NotificationHelper.swift
//  DeadLineTodo
//
//  Created by Haiyao Zhou on 10/04/2025.
//

import Foundation
import SwiftUI

class NotificationHelper {
    let reminderService = ReminderService()
    let calendarService = CalendarService()
    
    func cancelAllNotifications(for todo: TodoData) {
        for i in 1...4 {
            cancelPendingNotification(withIdentifier: todo.id.uuidString + "\(i)")
        }
    }
    
    func sendAllNotifications(todo: TodoData) {
        sendNotification1(todo: todo)
        sendNotification2(todo: todo, day: Double(todo.Day), hour: Double(todo.Hour), min: Double(todo.Min))
        sendNotification3(todo: todo)
        if todo.doing {
            sendNotification4(todo: todo)
        }
    }
    
    func sendNotification1(todo: TodoData) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = NSLocalizedString("将截止", comment: "")
        notificationContent.subtitle = todo.content

        if getLeftTime(todo: todo) > 0{
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: getLeftTime(todo: todo), repeats: false)
            let req = UNNotificationRequest(identifier: todo.id.uuidString + "1", content: notificationContent, trigger: trigger)
            UNUserNotificationCenter.current().add(req)
        }
    }
    
    func sendNotification2(todo: TodoData, day: Double, hour: Double, min: Double) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = NSLocalizedString("已截止", comment: "")
        notificationContent.subtitle = todo.content
        
        if getLeftTime(todo: todo) + getNeedTime(day: day, hour: hour, min: min) > 0 {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: getLeftTime(todo: todo) + getNeedTime(day: day, hour: hour, min: min), repeats: false)
            let req = UNNotificationRequest(identifier: todo.id.uuidString + "2", content: notificationContent, trigger: trigger)
            UNUserNotificationCenter.current().add(req)
        }
    }
    
    func sendNotification3(todo: TodoData) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = NSLocalizedString("紧急！", comment: "")
        notificationContent.subtitle = todo.content
        
        if todo.emergencyDate.timeIntervalSince1970 - Date().timeIntervalSince1970 > 0{
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: todo.emergencyDate.timeIntervalSince1970 - Date().timeIntervalSince1970, repeats: false)
            let req = UNNotificationRequest(identifier: todo.id.uuidString + "3", content: notificationContent, trigger: trigger)
            UNUserNotificationCenter.current().add(req)
        }
    }
    
    func sendNotification4(todo: TodoData) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = NSLocalizedString("任务超时", comment: "")
        notificationContent.subtitle = todo.content
        
        if todo.needTime - todo.lastTime > 0{
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: todo.needTime - todo.lastTime, repeats: false)
            let req = UNNotificationRequest(identifier: todo.id.uuidString + "4", content: notificationContent, trigger: trigger)
            UNUserNotificationCenter.current().add(req)
        }
        // you could also use...
        // UNCalendarNotificationTrigger(dateMatching: .init(year: 2022, month: 12, day: 10, hour: 0, minute: 0), repeats: true
    }
    
    func getNeedTime(day: Double, hour: Double, min: Double) -> Double {
        return day*60*60*24 + hour*60*60 + min*60
    }
    
    func getLeftTime(todo: TodoData) -> TimeInterval {
        let time = todo.Day*60*60*24 + todo.Hour*60*60 + todo.Min*60
        let leftTime = todo.endDate.timeIntervalSince1970 - Date().timeIntervalSince1970 - Double(time)
        return leftTime
    }
    
    func cancelPendingNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
