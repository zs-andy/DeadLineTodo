//
//  EditTodoBodyView.swift
//  DeadLineTodo
//
//  Created by Haiyao Zhou on 10/04/2025.
//

import Foundation
import SwiftUI
import SwiftData
import EventKit
import WidgetKit

struct EditTodoBodyView: View {
    @Environment(\.modelContext) var modelContext

    @Binding var edittodo: TodoData
    @Binding var calendar2Id: Int
    @Binding var calendarId: Int
    @Binding var EditTodoIsPresent: Bool
    @Binding var selectedPriority: Int
    @Binding var selectedCycle: Int
    
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
    @State var cycle:[String] = ["无","天","周","月"]
    @State var priority:[String] = ["无","高","中","低"]

    @Query var userSetting: [UserSetting]
    
    let reminderService = ReminderService()
    let calendarService = CalendarService()
    let calendarHelper = CalendarHelper()
    let reminderHelper = ReminderHelper()
    let notificationHelper = NotificationHelper()
    let helper = Helper()
    let service = Service()
    
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
        if ((/*edittodo.emergencyDate.timeIntervalSince1970 < Date().timeIntervalSince1970 ||*/ edittodo.emergencyDate.timeIntervalSince1970 > edittodo.endDate.timeIntervalSince1970 - needTime) && emergencyDate != edittodo.emergencyDate) || (edittodo.endDate.timeIntervalSince1970 < Date().timeIntervalSince1970 && endDate != edittodo.endDate) || (service.getLeftTime(todo: edittodo) <= 0 && edittodo.endDate.timeIntervalSince1970 - edittodo.addDate.timeIntervalSince1970 < needTime){
            if (/*edittodo.emergencyDate.timeIntervalSince1970 < Date().timeIntervalSince1970 ||*/ edittodo.emergencyDate.timeIntervalSince1970 > edittodo.endDate.timeIntervalSince1970 - needTime) && emergencyDate != edittodo.emergencyDate{
                helper.calendarPlusOne(calendarId: &calendarId, calendar2Id: &calendar2Id)
                showAlert = true
                showAlertEmergencyTime = true
                edittodo.emergencyDate = emergencyDate
            }
            if edittodo.endDate < Date() && endDate != edittodo.endDate{
                helper.calendarPlusOne(calendarId: &calendarId, calendar2Id: &calendar2Id)
                showAlert = true
                showAlertEndTime = true
                edittodo.endDate = endDate
            }else{
                if edittodo.endDate.timeIntervalSince1970 - edittodo.addDate.timeIntervalSince1970 < needTime{
                    helper.calendarPlusOne(calendarId: &calendarId, calendar2Id: &calendar2Id)
                    showAlert = true
                    showAlertNeedTime = true
                    edittodo.Day = day
                    edittodo.Hour = hour
                    edittodo.Min = min
                    edittodo.needTime = needTime
                }
            }
        } else {
            helper.calendarPlusOne(calendarId: &calendarId, calendar2Id: &calendar2Id)
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
}

