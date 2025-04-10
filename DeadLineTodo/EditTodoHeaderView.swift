//
//  EditTodoHeaderView.swift
//  DeadLineTodo
//
//  Created by Haiyao Zhou on 10/04/2025.
//

import Foundation
import SwiftUI
import SwiftData
import EventKit
import WidgetKit

struct EditTodoHeaderView: View {
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
    let service = Service()
    
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
                            service.calculateRepeatDay(edittodo: &edittodo, repeatTime: edittodo.repeatTime)
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

