//
//  EditTodoView.swift
//  DeadLineTodo
//
//  Created by Andy on 2024/1/24.
//

import SwiftUI
import SwiftData
import EventKit

struct EditTodoView: View {
    @Binding var EditTodoIsPresent: Bool
    @Environment(\.modelContext) var modelContext
    
    @State private var calendarId: Int = 0
    @State private var calendar2Id: Int = 0
    
    @State var priority:[String] = ["无","高","中","低"]
    @State var selectedPriority: Int = 0
    @State var selectedCycle: Int = 0
    @State var cycle:[String] = ["无","天","周","月"]
    @State var edittodo: TodoData
    
    @State private var title:String = ""
    @State private var day: Int = 0
    @State private var hour: Int = 0
    @State private var min: Int = 0
    @State private var needTIme: TimeInterval = 0
    @State private var emergencyDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var priorityInt: Int = 0
    @State private var repeatTime: Int = 0
    
    @State var cancelTime: Int = 0
    
    @State private var showAlert = false
    @State private var showAlertEndTime = false
    @State private var showAlertEmergencyTime = false
    @State private var showAlertNeedTime = false
    
    // 取消待处理通知
    func cancelPendingNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func sendNotification1(todo: TodoData) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = NSLocalizedString("将截止", comment: "")
        notificationContent.subtitle = todo.content

        if getLeftTime(todo: todo) ?? 0 > 0{
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: getLeftTime(todo: todo) ?? 0, repeats: false)
            let req = UNNotificationRequest(identifier: todo.id.uuidString + "1", content: notificationContent, trigger: trigger)
            UNUserNotificationCenter.current().add(req)
        }
    }
    func sendNotification2(todo: TodoData, day: Double, hour: Double, min: Double) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = NSLocalizedString("已截止", comment: "")
        notificationContent.subtitle = todo.content
        
        if (getLeftTime(todo: todo) ?? 0) + getNeedTime(day: day, hour: hour, min: min) > 0 {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: (getLeftTime(todo: todo) ?? 0) + getNeedTime(day: day, hour: hour, min: min), repeats: false)
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
    
    func getLeftTime(todo: TodoData) -> TimeInterval? {
        let time = todo.Day*60*60*24 + todo.Hour*60*60 + todo.Min*60
        let leftTime = todo.endDate.timeIntervalSince1970 - Date().timeIntervalSince1970 - Double(time)
        return leftTime
    }
    func getNeedTime(day: Double, hour: Double, min: Double) -> Double {
        return day*60*60*24 + hour*60*60 + min*60
    }
//    @State var selectedSeconds: Int = 0
    
    var body: some View {
        ZStack{
            VStack(){
                EditHeader(edittodo: $edittodo, cancelTime: $cancelTime, EditTodoIsPresent: $EditTodoIsPresent, selectedPriority: $selectedPriority)
                EditBody(edittodo: $edittodo, calendar2Id: $calendar2Id, calendarId: $calendarId, EditTodoIsPresent: $EditTodoIsPresent, selectedPriority: $selectedPriority, selectedCycle: $selectedCycle)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.grayWhite1)
    }
}

