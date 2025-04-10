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
    
    let reminderService = ReminderService()
    let calendarService = CalendarService()
    let calendarHelper = CalendarHelper()
    let reminderHelper = ReminderHelper()
    let notificationHelper = NotificationHelper()
    let helper = Helper()
    
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
                        notificationHelper.sendAllNotifications(todo: edittodo)
                        reminderService.addEventToReminders(title: edittodo.content, priority: selectedPriority, dueDate: edittodo.endDate, remindDate: edittodo.emergencyDate, edittodo: edittodo)
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
                            notificationHelper.cancelAllNotifications(for: edittodo)
                            //Refactored the logic to Helper
                            helper.calculateRepeatDay(edittodo: &edittodo, repeatTime: edittodo.repeatTime)
                            notificationHelper.sendAllNotifications(todo: edittodo)
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
    
    let reminderService = ReminderService()
    let calendarService = CalendarService()
    let calendarHelper = CalendarHelper()
    let reminderHelper = ReminderHelper()
    let notificationHelper = NotificationHelper()
    let helper = Helper()
    
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
        switch edittodo.priority{
        case 0:
            selectedPriority = 0
        case 1:
            selectedPriority = 1
        case 5:
            selectedPriority = 2
        default:
            selectedPriority = 3
        }
    }
    
    func confirm() {
        let needTime = TimeInterval(edittodo.Day*24*60*60 + edittodo.Hour*60*60 + edittodo.Min*60)
        if ((/*edittodo.emergencyDate.timeIntervalSince1970 < Date().timeIntervalSince1970 ||*/ edittodo.emergencyDate.timeIntervalSince1970 > edittodo.endDate.timeIntervalSince1970 - needTime) && emergencyDate != edittodo.emergencyDate) || (edittodo.endDate.timeIntervalSince1970 < Date().timeIntervalSince1970 && endDate != edittodo.endDate) || (helper.getLeftTime(todo: edittodo) <= 0 && edittodo.endDate.timeIntervalSince1970 - edittodo.addDate.timeIntervalSince1970 < needTime){
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
            for i in 0..<4{
                notificationHelper.cancelPendingNotification(withIdentifier: edittodo.id.uuidString + String(i))
            }
            if edittodo.doing == true{
                notificationHelper.sendNotification4(todo: edittodo)
            }
            notificationHelper.sendAllNotifications(todo: edittodo)
            if userSetting[0].reminder{
                reminderService.editEventToReminders(title: title, priority: selectedPriority, editTo: edittodo.content, dueDate: edittodo.emergencyDate, remindDate: edittodo.emergencyDate, edittodo: edittodo)
            }else{
                reminderService.removeEventToReminders(title: title)
                switch selectedPriority {
                case 0:
                    edittodo.priority = 0
                case 1:
                    edittodo.priority = 1
                case 2:
                    edittodo.priority = 5
                case 3:
                    edittodo.priority = 9
                default:
                    break
                }
            }
            if userSetting[0].calendar{
                calendarService.editEventInCalendar(oldTitle: title, newTitle: edittodo.content, startDate: edittodo.emergencyDate, dueDate: Date(timeIntervalSince1970: edittodo.emergencyDate.timeIntervalSince1970 + needTime))
            }else{
                calendarService.deleteEventFromCalendar(title: title)
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
    
    func cancelPendingNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
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
