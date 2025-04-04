//
//  EditView.swift
//  DeadLineTodo
//
//  Created by Andy on 2024/3/8.
//

import Foundation
import SwiftUI
import SwiftData
import EventKit
import WidgetKit

struct EditHeader: View {
    @Binding var edittodo: TodoData
    @Binding var cancelTime: Int
    @Binding var EditTodoIsPresent: Bool
    @Binding var selectedPriority: Int
    @Environment(\.modelContext) var modelContext
    
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
    
    func addEventToReminders(title: String, priority: Int, dueDate: Date, remindDate: Date){
        let eventStore = EKEventStore()
        let newEvent = EKReminder(eventStore: eventStore)

        newEvent.title = title
        newEvent.calendar = eventStore.defaultCalendarForNewReminders()
        if priority == 0 {
            newEvent.priority = 0
            edittodo.priority = 0
        }else if priority == 1{
            newEvent.priority = 1
            edittodo.priority = 1
        }else if priority == 2 {
            newEvent.priority = 5
            edittodo.priority = 5
        }else{
            newEvent.priority = 9
            edittodo.priority = 9
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
    
    var body: some View {
        VStack{
            HStack{
                Text("编辑任务")
                    .bold()
                    .font(.system(size: 30))
                    .padding()
                    .foregroundStyle(Color.myBlack)
                Spacer()
            }
            HStack{
                TextField("输入任务内容", text: $edittodo.content)
                    .bold()
                    .padding()
                    .foregroundStyle(Color.blackBlue1)
                    .font(.system(size: 25))
                if edittodo.done {
                    //完成撤回按钮
                    Button(action:{
                        sendNotification1(todo: edittodo)
                        sendNotification2(todo: edittodo, day: Double(edittodo.Day), hour: Double(edittodo.Hour), min: Double(edittodo.Min))
                        sendNotification3(todo: edittodo)
                        addEventToReminders(title: edittodo.content, priority: selectedPriority, dueDate: edittodo.endDate, remindDate: edittodo.emergencyDate)
                        edittodo.done = false
                        edittodo.todo = true
                        EditTodoIsPresent = false
                    }){
                        ZStack{
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(Color.blackBlue2)
                                .frame(width: 50, height: 35)
                            Text("未完成")
                                .bold()
                                .foregroundStyle(Color.white)
                                .font(.system(size: 12))
                        }
                    }
                    .padding(.horizontal)
                }else{
                    if edittodo.repeatTime != 0 && cancelTime == 0{
                        Button(action:{
                            cancelTime += 1
                            edittodo.times = 0
                            cancelPendingNotification(withIdentifier: edittodo.id.uuidString + "1")
                            cancelPendingNotification(withIdentifier: edittodo.id.uuidString + "2")
                            cancelPendingNotification(withIdentifier: edittodo.id.uuidString + "3")
                            cancelPendingNotification(withIdentifier: edittodo.id.uuidString + "4")
                            if edittodo.repeatTime == 1 {
                                edittodo.endDate = Date(timeIntervalSince1970: edittodo.endDate.timeIntervalSince1970 + 60*60*24)
                                edittodo.emergencyDate = Date(timeIntervalSince1970: edittodo.emergencyDate.timeIntervalSince1970 + 60*60*24)
                                edittodo.addDate = getStartOfDay(startDate: edittodo.emergencyDate)
                                while edittodo.emergencyDate.timeIntervalSince1970 < Date().timeIntervalSince1970 {
                                    edittodo.endDate = Date(timeIntervalSince1970: edittodo.endDate.timeIntervalSince1970 + 60*60*24)
                                    edittodo.emergencyDate = Date(timeIntervalSince1970: edittodo.emergencyDate.timeIntervalSince1970 + 60*60*24)
                                    edittodo.addDate = getStartOfDay(startDate: edittodo.emergencyDate)
                                }
                            }else if edittodo.repeatTime == 2 {
                                edittodo.endDate = Date(timeIntervalSince1970: edittodo.endDate.timeIntervalSince1970 + 60*60*24*7)
                                edittodo.emergencyDate = Date(timeIntervalSince1970: edittodo.emergencyDate.timeIntervalSince1970 + 60*60*24*7)
                                edittodo.addDate = getStartOfWeek(startDate: edittodo.emergencyDate)
                                while edittodo.emergencyDate.timeIntervalSince1970 < Date().timeIntervalSince1970 {
                                    edittodo.endDate = Date(timeIntervalSince1970: edittodo.endDate.timeIntervalSince1970 + 60*60*24*7)
                                    edittodo.emergencyDate = Date(timeIntervalSince1970: edittodo.emergencyDate.timeIntervalSince1970 + 60*60*24*7)
                                    edittodo.addDate = getStartOfWeek(startDate: edittodo.emergencyDate)
                                }
                            }else if edittodo.repeatTime == 3 {
                                edittodo.endDate = Date(timeIntervalSince1970: edittodo.endDate.timeIntervalSince1970 + 60*60*24*7*30)
                                edittodo.emergencyDate = Date(timeIntervalSince1970: edittodo.emergencyDate.timeIntervalSince1970 + 60*60*24*7*30)
                                edittodo.addDate = getStartOfMonth(startDate: edittodo.emergencyDate)
                                while edittodo.emergencyDate.timeIntervalSince1970 < Date().timeIntervalSince1970 {
                                    edittodo.endDate = Date(timeIntervalSince1970: edittodo.endDate.timeIntervalSince1970 + 60*60*24*7*30)
                                    edittodo.emergencyDate = Date(timeIntervalSince1970: edittodo.emergencyDate.timeIntervalSince1970 + 60*60*24*7*30)
                                    edittodo.addDate = getStartOfMonth(startDate: edittodo.emergencyDate)
                                }
                            }
                            sendNotification1(todo: edittodo)
                            sendNotification2(todo: edittodo, day: Double(edittodo.Day), hour: Double(edittodo.Hour), min: Double(edittodo.Min))
                            sendNotification3(todo: edittodo)
                            EditTodoIsPresent = false
                        }){
                            ZStack{
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .fill(Color.blackBlue2)
                                    .frame(width: 50, height: 35)
                                Text("取消")
                                    .bold()
                                    .foregroundStyle(Color.white)
                                    .font(.system(size: 12))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .background(Color.creamBlue)
    }
    
    func cancelPendingNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func getNeedTime(day: Double, hour: Double, min: Double) -> Double {
        return day*60*60*24 + hour*60*60 + min*60
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
    
    func getLeftTime(todo: TodoData) -> TimeInterval {
        let time = todo.Day*60*60*24 + todo.Hour*60*60 + todo.Min*60
        let leftTime = todo.endDate.timeIntervalSince1970 - Date().timeIntervalSince1970 - Double(time)
        return leftTime
    }
}

struct EditBody: View {
    @Binding var edittodo: TodoData
    @Binding var calendar2Id: Int
    @Binding var calendarId: Int
    @Binding var EditTodoIsPresent: Bool
    @State var title:String = ""
    @State var day: Int = 0
    @State var hour: Int = 0
    @State var min: Int = 0
    @State var needTIme: TimeInterval = 0
    @State var emergencyDate: Date = Date()
    @State var endDate: Date = Date()
    @State var priorityInt: Int = 0
    @State var repeatTime: Int = 0
    @State var showAlert = false
    @State var showAlertEndTime = false
    @State var showAlertEmergencyTime = false
    @State var showAlertNeedTime = false
    
    @Binding var selectedPriority: Int
    @Binding var selectedCycle: Int
    
    @Query var userSetting: [UserSetting]
    @Environment(\.modelContext) var modelContext
    
    func appear(){
        title = edittodo.content
        day = edittodo.Day
        hour = edittodo.Hour
        min = edittodo.Min
        needTIme = TimeInterval(day*24*60*60 + hour*60*60 + min*60)
        emergencyDate = edittodo.emergencyDate
        endDate = edittodo.endDate
        priorityInt = edittodo.priority
        repeatTime = edittodo.repeatTime
        print(edittodo.priority)
        if edittodo.priority == 0{
            selectedPriority = 0
        }else if edittodo.priority == 1{
            selectedPriority = 1
        }else if edittodo.priority == 5{
            selectedPriority = 2
        }else{
            selectedPriority = 3
        }
    }
    
    func confirm() {
        let needTime = TimeInterval(edittodo.Day*24*60*60 + edittodo.Hour*60*60 + edittodo.Min*60)
        if ((/*edittodo.emergencyDate.timeIntervalSince1970 < Date().timeIntervalSince1970 ||*/ edittodo.emergencyDate.timeIntervalSince1970 > edittodo.endDate.timeIntervalSince1970 - needTime) && emergencyDate != edittodo.emergencyDate) || (edittodo.endDate.timeIntervalSince1970 < Date().timeIntervalSince1970 && endDate != edittodo.endDate) || (getLeftTime(todo: edittodo) <= 0 && edittodo.endDate.timeIntervalSince1970 - edittodo.addDate.timeIntervalSince1970 < needTime){
            if (/*edittodo.emergencyDate.timeIntervalSince1970 < Date().timeIntervalSince1970 ||*/ edittodo.emergencyDate.timeIntervalSince1970 > edittodo.endDate.timeIntervalSince1970 - needTime) && emergencyDate != edittodo.emergencyDate{
                calendarId += 1
                calendar2Id += 1
                showAlert = true
                showAlertEmergencyTime = true
                edittodo.emergencyDate = emergencyDate
            }
            if edittodo.endDate < Date() && endDate != edittodo.endDate{
                calendarId += 1
                calendar2Id += 1
                showAlert = true
                showAlertEndTime = true
                edittodo.endDate = endDate
            }else{
                if edittodo.endDate.timeIntervalSince1970 - edittodo.addDate.timeIntervalSince1970 < needTime{
                    calendarId += 1
                    calendar2Id += 1
                    showAlert = true
                    showAlertNeedTime = true
                    edittodo.Day = day
                    edittodo.Hour = hour
                    edittodo.Min = min
                    edittodo.needTime = needTime
                }
            }
        } else {
            calendarId += 1
            calendar2Id += 1
            if edittodo.content == ""{
                edittodo.content = NSLocalizedString("请输入任务内容", comment: "")
            }
            edittodo.needTime = edittodo.actualFinishTime + TimeInterval(edittodo.Day*24*60*60 + edittodo.Hour*60*60 + edittodo.Min*60)
            edittodo.initialNeedTime = TimeInterval(needTime)
            edittodo.Sec = 0
            cancelPendingNotification(withIdentifier: edittodo.id.uuidString + "1")
            cancelPendingNotification(withIdentifier: edittodo.id.uuidString + "2")
            cancelPendingNotification(withIdentifier: edittodo.id.uuidString + "3")
            cancelPendingNotification(withIdentifier: edittodo.id.uuidString + "4")
            if edittodo.doing == true{
                sendNotification4(todo: edittodo)
            }
            sendNotification1(todo: edittodo)
            sendNotification2(todo: edittodo, day: Double(edittodo.Day), hour: Double(edittodo.Hour), min: Double(edittodo.Min))
            sendNotification3(todo: edittodo)
            if userSetting[0].reminder{
                editEventToReminders(title: title, priority: selectedPriority, editTo: edittodo.content, dueDate: edittodo.emergencyDate, remindDate: edittodo.emergencyDate)
            }else{
                removeEventToReminders(title: title)
                if selectedPriority == 0 {
                    edittodo.priority = 0
                }else if selectedPriority == 1{
                    edittodo.priority = 1
                }else if selectedPriority == 2 {
                    edittodo.priority = 5
                }else{
                    edittodo.priority = 9
                }
            }
            if userSetting[0].calendar{
                editEventInCalendar(oldTitle: title, newTitle: edittodo.content, startDate: edittodo.emergencyDate, dueDate: Date(timeIntervalSince1970: edittodo.emergencyDate.timeIntervalSince1970 + needTime))
            }else{
                deleteEventFromCalendar(title: title)
            }
            EditTodoIsPresent = false
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func cancel(){
        calendarId += 1
        calendar2Id += 1
        edittodo.content = title
        edittodo.Day = day
        edittodo.Hour = hour
        edittodo.Min = min
        needTIme = TimeInterval(day*24*60*60 + hour*60*60 + min*60)
        edittodo.emergencyDate = emergencyDate
        edittodo.endDate = endDate
        edittodo.priority = priorityInt
        edittodo.repeatTime = repeatTime
        EditTodoIsPresent = false
    }
    
    func editEventToReminders(title: String, priority: Int, editTo: String, dueDate: Date, remindDate: Date){
        let eventStore = EKEventStore()
        // 创建一个谓词以查找具有指定标题的提醒事项
        let predicate = eventStore.predicateForReminders(in: nil)
        
        // 指定提醒事项的标题
        let reminderTitleToModify = title

        // 获取提醒事项
        eventStore.fetchReminders(matching: predicate) { (reminders) in
            // 遍历提醒事项列表，找到要修改的提醒事项
            if let matchingReminder = reminders?.first(where: { $0.title == reminderTitleToModify }) {
                // 修改提醒事项的属性
                matchingReminder.title = editTo
                if priority == 0 {
                    matchingReminder.priority = 0
                    edittodo.priority = 0
                }else if priority == 1{
                    matchingReminder.priority = 1
                    edittodo.priority = 1
                }else if priority == 2 {
                    matchingReminder.priority = 5
                    edittodo.priority = 5
                }else{
                    matchingReminder.priority = 9
                    edittodo.priority = 9
                }
                let calendar = Calendar.current
                let dueDateComponents = calendar.dateComponents([.year, .month, .day], from: dueDate)
                matchingReminder.dueDateComponents = dueDateComponents
                
                let alarm = EKAlarm(absoluteDate: remindDate)
                for alarm in matchingReminder.alarms ?? [] {
                    matchingReminder.removeAlarm(alarm)
               }
                matchingReminder.addAlarm(alarm)
                
                // 保存修改
                do {
                    try eventStore.save(matchingReminder, commit: true)
                    print("提醒事项修改成功")
                } catch {
                    print("提醒事项修改失败: \(error.localizedDescription)")
                }
            } else {
                print("未找到要修改的提醒事项")
                addEventToReminders(title: editTo, priority: priority, dueDate: dueDate, remindDate: remindDate)
            }
        }
    }
    
    func addEventToCalendar(title: String, startDate: Date, dueDate: Date) {
        let eventStore = EKEventStore()
        
        let newEvent = EKEvent(eventStore: eventStore)
        newEvent.title = title
        newEvent.calendar = eventStore.defaultCalendarForNewEvents
        
        newEvent.startDate = startDate
        newEvent.endDate = dueDate
        
        let alarm = EKAlarm(absoluteDate: startDate)
        newEvent.addAlarm(alarm)
        
        print("add")
        
        do {
            try eventStore.save(newEvent, span: .thisEvent)
            print("Event saved successfully")
        } catch let error {
            print("Event failed with error: \(error.localizedDescription)")
        }
    }
    
    func editEventInCalendar(oldTitle: String, newTitle: String, startDate: Date, dueDate: Date) {
        let eventStore = EKEventStore()
        let predicate = eventStore.predicateForEvents(withStart: Date(), end: Date().addingTimeInterval(31 * 24 * 60 * 60), calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        for event in events {
            if event.title == oldTitle {
                event.title = newTitle
                
                event.startDate = startDate
                event.endDate = dueDate
                
                if let alarms = event.alarms {
                    for alarm in alarms {
                        event.removeAlarm(alarm)
                    }
                }
                
                let alarm = EKAlarm(absoluteDate: startDate)
                event.addAlarm(alarm)
                
                do {
                    try eventStore.save(event, span: .thisEvent)
                    print("事件修改成功")
                    return
                } catch {
                    print("事件修改失败: \(error.localizedDescription)")
                    return
                }
            }
        }
        addEventToCalendar(title: newTitle,startDate: startDate, dueDate: dueDate)
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
    
    func addEventToReminders(title: String, priority: Int, dueDate: Date, remindDate: Date){
        let eventStore = EKEventStore()
        let newEvent = EKReminder(eventStore: eventStore)

        newEvent.title = title
        newEvent.calendar = eventStore.defaultCalendarForNewReminders()
        if priority == 0 {
            newEvent.priority = 0
            edittodo.priority = 0
        }else if priority == 1{
            newEvent.priority = 1
            edittodo.priority = 1
        }else if priority == 2 {
            newEvent.priority = 5
            edittodo.priority = 5
        }else{
            newEvent.priority = 9
            edittodo.priority = 9
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
    
    func cancelPendingNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func getNeedTime(day: Double, hour: Double, min: Double) -> Double {
        return day*60*60*24 + hour*60*60 + min*60
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
    
    func getLeftTime(todo: TodoData) -> TimeInterval {
        let time = todo.Day*60*60*24 + todo.Hour*60*60 + todo.Min*60
        let leftTime = todo.endDate.timeIntervalSince1970 - Date().timeIntervalSince1970 - Double(time)
        return leftTime
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
    
    @State var cycle:[String] = ["无","天","周","月"]
    @State var priority:[String] = ["无","高","中","低"]
    
    var body: some View {
        ScrollView(showsIndicators: false){
            HStack{
                Text("任务优先级")
                    .bold()
                    .foregroundStyle(Color.myBlack)
                Spacer()
                Picker("f", selection: $selectedPriority) {
                    ForEach(0..<4, id: \.self) { f in
                        Text(LocalizedStringKey(priority[f]))
                            .bold()
                            .foregroundStyle(Color.myBlack)
                    }
                }
                .accentColor(Color.blackBlue1)
                .pickerStyle(DefaultPickerStyle())
            }
            .padding(.top)
            .padding(.horizontal)
            HStack{
                Text("任务重复周期")
                    .bold()
                    .foregroundStyle(Color.myBlack)
                Spacer()
                Picker("f", selection: $edittodo.repeatTime) {
                    ForEach(0..<4, id: \.self) { f in
                        Text(LocalizedStringKey(cycle[f]))
                            .bold()
                            .foregroundStyle(Color.myBlack)
                    }
                }
                .accentColor(Color.blackBlue1)
                .pickerStyle(DefaultPickerStyle())
            }
            .padding(.horizontal)
            DatePicker("开始日期", selection: $edittodo.emergencyDate)
                .foregroundStyle(Color.myBlack)
                .datePickerStyle(CompactDatePickerStyle())
                .padding(.horizontal)
                .bold()
                .accentColor(.blackBlue2)
                .id(calendar2Id)
            DatePicker("截止日期", selection: $edittodo.endDate)
                .foregroundStyle(Color.myBlack)
                .datePickerStyle(CompactDatePickerStyle())
                .padding(.horizontal)
                .bold()
                .accentColor(.blackBlue2)
                .id(calendarId)
            HStack{
                Text("所需时间：")
                    .foregroundStyle(Color.myBlack)
                    .bold()
                    .padding()
                Spacer()
            }
            HStack{
                HStack {
                    VStack{
                        Text("天")
                            .foregroundStyle(Color.myBlack)
                            .bold()
                        Picker("Days", selection: $edittodo.Day) {
                            ForEach(0..<32, id: \.self) { day in
                                Text("\(day)")
                            }
                        }
                        .id(edittodo.Day)
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 150)
                    }
                    .frame(maxWidth: .infinity)
                    VStack{
                        Text("时")
                            .foregroundStyle(Color.myBlack)
                            .bold()
                        Picker("Hours", selection: $edittodo.Hour) {
                            ForEach(0..<25, id: \.self) { hour in
                                Text("\(hour)")
                            }
                        }
                        .id(edittodo.Hour)
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 150)
                    }
                    .frame(maxWidth: .infinity)
                    VStack{
                        Text("分")
                            .foregroundStyle(Color.myBlack)
                            .bold()
                        Picker("Minutes", selection: $edittodo.Min) {
                            ForEach(0..<61, id: \.self) { minute in
                                Text("\(minute)")
                            }
                        }
                        .id(edittodo.Min)
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 150)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
            }
        }
        ZStack{
            HStack{
                ZStack{
                    Button(action: {
                        cancel()
                        WidgetCenter.shared.reloadAllTimelines()
                    }){
                        ZStack{
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(Color.creamBlue)
                                .frame(width: 80, height: 50)
                            Text("取消")
                                .bold()
                                .foregroundStyle(Color.white)
                        }
                    }
                    .padding(.vertical)
                }
                .frame(maxWidth: .infinity)
                ZStack{
                    Button(action: {
                        confirm()
                    }){
                        ZStack{
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(Color.blackBlue2)
                                .frame(width: 80, height: 50)
                            Text("确定")
                                .bold()
                                .foregroundStyle(Color.white)
                        }
                    }
                    .padding(.vertical)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .alert(isPresented: $showAlert) {
            if showAlertEndTime {
                Alert(title: Text("提醒"), message: Text("截止时间在过去"), dismissButton: .default(Text("确定")){
                    showAlertEndTime = false
                    showAlert = false
                })
            }else if showAlertEmergencyTime {
                Alert(title: Text("提醒"), message: Text("开始时间不在允许范围内"), dismissButton: .default(Text("确定")){
                    showAlertEmergencyTime = false
                    showAlert = false
                })
            }else{
                Alert(title: Text("提醒"), message: Text("任务所需时间超过截止时间"), dismissButton: .default(Text("确定")){
                    showAlertNeedTime = false
                    showAlert = false
                })
            }
        }
        .onAppear {
            appear()
        }
    }
}
