//
//  SearchTodoService.swift
//  DeadLineTodo
//
//  Created by Haiyao Zhou on 11/04/2025.
//

import Foundation
import EventKit
import SwiftUI
import WidgetKit
import SwiftData

class SearchTodoService{
    let eventStore = EKEventStore()

    func addEventToReminders(title: String, priority: Int, dueDate: Date, remindDate: Date){
        let newEvent = EKReminder(eventStore: eventStore)

        newEvent.title = title
        newEvent.calendar = eventStore.defaultCalendarForNewReminders()
        if priority == 0 {
            newEvent.priority = 0
        }else if priority == 1{
            newEvent.priority = 1
        }else if priority == 2 {
            newEvent.priority = 5
        }else{
            newEvent.priority = 9
        }
        
        let calendar = Calendar.current
        let dueDateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        newEvent.dueDateComponents = dueDateComponents
        
        let alarm = EKAlarm(absoluteDate: remindDate)
        newEvent.addAlarm(alarm)
        
        do {
            try eventStore.save(newEvent, commit: true)
            print(newEvent.priority)
        } catch let error {
            print("Reminder failed with error \(error)")
        }
    }
    
    
    func filterTodos(todo: TodoData, searchText: String) -> Bool{
        if searchText.isEmpty == false{
            return todo.content.lowercased().contains(searchText.lowercased())
        } else {
            return false
        }
    }
    
    
    func removeEventToReminders(title: String){
        let eventStore = EKEventStore()
        // 创建一个谓词以查找具有指定标题的提醒事项
        let predicate = eventStore.predicateForReminders(in: nil)
        
        // 指定提醒事项的标题
        let reminderTitleToModify = title

        // 获取提醒事项
        eventStore.fetchReminders(matching: predicate) { (reminders) in
            // 遍历提醒事项列表，找到要修改的提醒事项
            if let matchingReminder = reminders?.first(where: { $0.title == reminderTitleToModify }) {
                // 保存修改
                do {
                    try eventStore.remove(matchingReminder, commit: true)
                    print("提醒事项删除成功")
                } catch {
                    print("提醒事项删除失败: \(error.localizedDescription)")
                }
            } else {
                print("未找到要修改的提醒事项")
            }
        }
    }
    
    
    func cancelPendingNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
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
        // you could also use...
        // UNCalendarNotificationTrigger(dateMatching: .init(year: 2022, month: 12, day: 10, hour: 0, minute: 0), repeats: true
    }
    
    
    func sendNotification2(todo: TodoData, day: Double, hour: Double, min: Double) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = NSLocalizedString("已截止", comment: "")
        notificationContent.subtitle = todo.content

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: getLeftTime(todo: todo) + getNeedTime(todo: todo), repeats: false)
        // you could also use...
        // UNCalendarNotificationTrigger(dateMatching: .init(year: 2022, month: 12, day: 10, hour: 0, minute: 0), repeats: true)

        let req = UNNotificationRequest(identifier: todo.id.uuidString + "2", content: notificationContent, trigger: trigger)

        UNUserNotificationCenter.current().add(req)
    }
    
    
    func sendNotification3(todo: TodoData) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = NSLocalizedString("紧急！", comment: "")
        notificationContent.subtitle = todo.content

        if todo.emergencyDate.timeIntervalSince1970 - Date().timeIntervalSince1970 > 0 {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: todo.emergencyDate.timeIntervalSince1970 - Date().timeIntervalSince1970, repeats: false)
            // you could also use...
            // UNCalendarNotificationTrigger(dateMatching: .init(year: 2022, month: 12, day: 10, hour: 0, minute: 0), repeats: true)

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
    
    
    func getNeedTime(todo: TodoData) -> TimeInterval {
        let time = todo.Day*60*60*24 + todo.Hour*60*60 + todo.Min*60
        return TimeInterval(time)
    }
    
    
    func getDateStringWithoutYear(date: Date) -> String {
        let dformatter = DateFormatter()
        dformatter.dateFormat = NSLocalizedString("MM月dd日", comment: "")
        return dformatter.string(from: date)
    }
    
    
    func getDateString(date: Date) -> String { //转换格式
        let dformatter = DateFormatter()
        dformatter.dateFormat = NSLocalizedString("yyyy年MM月dd日", comment: "")
        return dformatter.string(from: date)
    }
    
    
    func getTimeString(date: Date) -> String { //转换格式
        let dformatter = DateFormatter()
        dformatter.dateFormat = "hh:mm"
        return dformatter.string(from: date)
    }
    
    
    func decomposeSeconds(totalSeconds: TimeInterval) -> (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let days = Int(totalSeconds / (24 * 60 * 60))
        let remainingSeconds = totalSeconds - TimeInterval(days * 24 * 60 * 60)
        
        let hours = Int(remainingSeconds / 3600)
        let remainingSecondsAfterHours = remainingSeconds - TimeInterval(hours * 3600)
        
        let minutes = Int(remainingSecondsAfterHours / 60)
        let seconds = Int(remainingSecondsAfterHours.truncatingRemainder(dividingBy: 60))
        
        return (days, hours, minutes, seconds)
    }
    
    
    func getLeftTime(todo: TodoData) -> TimeInterval {
        let time = todo.Day*60*60*24 + todo.Hour*60*60 + todo.Min*60 + todo.Sec
        let leftTime = todo.endDate.timeIntervalSince1970 - Date().timeIntervalSince1970 - Double(time)
        return max(leftTime, 0)
    }
    
    
    func getOffset(todo: TodoData, width: Double) -> CGFloat {
        let offset = (Date().timeIntervalSince1970 - todo.addDate.timeIntervalSince1970) / (todo.endDate.timeIntervalSince1970 - todo.addDate.timeIntervalSince1970) * width
        return offset
    }
    
    
    func getSize(todo: TodoData, width: Double) -> CGFloat {
        let needTime = todo.needTime - todo.actualFinishTime
        let now = Date()
        let total = todo.endDate.timeIntervalSince1970 - now.timeIntervalSince1970
        let size = (Double(needTime) / total) * width
        if size >= 0 && size <= width{
            return size
        }else{
            return width
        }
    }
    
    
    func location(todo: TodoData, width: Double) -> CGFloat{
        let now = Date()
        let total = todo.endDate.timeIntervalSince1970 - now.timeIntervalSince1970
        let l = ((todo.emergencyDate.timeIntervalSince1970 - now.timeIntervalSince1970) / total)*width
        return l
    }
    
    
    func getStartOfDay(startDate: Date) -> Date{
        let currentDate = startDate
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let startOfDay = calendar.startOfDay(for: currentDate)
        
        return Date(timeIntervalSince1970: startOfDay.timeIntervalSince1970)
    }

    
    func getStartOfWeek(startDate: Date) -> Date{
        let currentDate = startDate
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        calendar.firstWeekday = 2
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
        return Date(timeIntervalSince1970: startOfWeek.timeIntervalSince1970)
    }
    
    
    func getStartOfMonth(startDate: Date) -> Date{
        let currentDate = startDate
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        return startOfMonth
    }
    
    
    func done(todo: TodoData, doneDate: Date, EmergencyNum: inout Int, notificationService: NotificationService, reminderService: ReminderService, calendarService: CalendarService, service: Service, modelContext: ModelContext, isAddDateAlertPresent: inout Bool) {
        if todo.addDate.timeIntervalSince1970 <= Date().timeIntervalSince1970{
            if todo.emergency {
                EmergencyNum -= 1
            }
            if todo.doing {
                todo.doing = false
                cancelPendingNotification(withIdentifier: todo.id.uuidString + "4")
                todo.lastTime = todo.actualFinishTime
                if todo.actualFinishTime < todo.needTime{
                    todo.Day = decomposeSeconds(totalSeconds: todo.needTime - todo.actualFinishTime).days
                    todo.Hour = decomposeSeconds(totalSeconds: todo.needTime - todo.actualFinishTime).hours
                    todo.Min = decomposeSeconds(totalSeconds: todo.needTime - todo.actualFinishTime).minutes
                    todo.Sec = decomposeSeconds(totalSeconds: todo.needTime - todo.actualFinishTime).seconds
                }else{
                    todo.Day = 0
                    todo.Hour = 0
                    todo.Min = 0
                    todo.Sec = 0
                }
            }
            notificationService.cancelAllNotifications(for: todo)
            reminderService.removeEventToReminders(title: todo.content)
            todo.doneDate = Date()
            todo.score = getScore(todo: todo)
            todo.offset = 0
            todo.todo = false
            todo.emergency = false
            todo.done = true
            if todo.repeatTime != 0 {
                var repeatTodo: TodoData = TodoData(content: todo.content, repeatTime: todo.repeatTime, priority: todo.priority, endDate: todo.endDate, addDate: Date(), doneDate: Date(), emergencyDate: todo.emergencyDate, startDoingDate: Date(), leftTime: 0,needTime: todo.initialNeedTime, actualFinishTime: 0, lastTime: 0, initialNeedTime: todo.initialNeedTime, Day: decomposeSeconds(totalSeconds: todo.initialNeedTime).days, Hour: decomposeSeconds(totalSeconds: todo.initialNeedTime).hours, Min: decomposeSeconds(totalSeconds: todo.initialNeedTime).minutes, Sec: decomposeSeconds(totalSeconds: todo.initialNeedTime).seconds, todo: true, done: false, emergency: false, doing: false, offset: 0,lastoffset: 0, score: 0, times: todo.times + 1)
                
                service.calculateRepeatTimeByEndDate(repeatTodo: &repeatTodo, repeatTime: todo.repeatTime, modelContext: modelContext)
                
                notificationService.sendAllNotifications(todo: repeatTodo)
                
                reminderService.addEventToReminders(title: repeatTodo.content, priority: repeatTodo.priority, dueDate: repeatTodo.endDate, remindDate: repeatTodo.emergencyDate, edittodo: todo)
                let time = repeatTodo.Day*24*60*60 + repeatTodo.Hour*60*60 + repeatTodo.Min*60
                calendarService.addEventToCalendar(title: repeatTodo.content, startDate: repeatTodo.emergencyDate, dueDate: Date(timeIntervalSince1970: repeatTodo.emergencyDate.timeIntervalSince1970 + Double(time)))
            }
            WidgetCenter.shared.reloadAllTimelines()
        }else{
            isAddDateAlertPresent = true
        }
    }
    
    
    func deleteEventFromCalendar(title: String) {
        let eventStore = EKEventStore()
        
        let predicate = eventStore.predicateForEvents(withStart: Date(), end: Date().addingTimeInterval(31 * 24 * 60 * 60), calendars: nil)
        
        let events = eventStore.events(matching: predicate)
        
        for event in events {
            if event.title == title {
                do {
                    try eventStore.remove(event, span: .thisEvent)
                    print("事件删除成功")
                    return
                } catch {
                    print("事件删除失败: \(error.localizedDescription)")
                    return
                }
            }
        }
        
        print("未找到要删除的事件")
    }
    
    
    func getScore(todo: TodoData) -> Int {//计算效率分数
        var score1: Double = 0
        var score2: Double = 0
        let needTime = todo.Day*60*60*24 + todo.Hour*60*60 + todo.Min*60 + todo.Sec
        let sum = todo.endDate.timeIntervalSince1970 - todo.addDate.timeIntervalSince1970
        score1 = (todo.endDate.timeIntervalSince1970 - todo.doneDate.timeIntervalSince1970 - Double(needTime)) / sum
        if score1 >= 1{
            score1 = 1
        }
        if score1 <= 0{
            score1 = 0
        }
        if todo.needTime >= todo.actualFinishTime {
            score2 = 100
        }else{
            if (todo.actualFinishTime - todo.needTime) / todo.needTime >= 1{
                score2 = 0
            }else{
                score2 = 100 - ((todo.actualFinishTime - todo.needTime) / todo.needTime) * 100
            }
        }
        return Int(score1 * 100 * 0.3) + Int(score2 * 0.7)
    }
    
    func cancelAllPendingNotifications(for todo: TodoData) {
        for i in 1...4 {
            cancelPendingNotification(withIdentifier: todo.id.uuidString + "\(i)")
        }
    }
}
