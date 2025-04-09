//
//  ReminderUtils.swift
//  DeadLineTodo
//
//  Created by Haiyao Zhou on 06/04/2025.
//

import Foundation
import EventKit

class ReminderService{
    private let eventStore = EKEventStore();
        
    func addEventToReminders(title: String, priority: Int, dueDate: Date, remindDate: Date, edittodo: TodoData){
        let newEvent = EKReminder(eventStore: eventStore)
        
        newEvent.priority = self.setPriority(for: priority)
        edittodo.priority = newEvent.priority
        
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
        
    private func setPriority(for priority: Int) -> Int{
        switch (priority){
        case 0:
            return 0
        case 1:
            return 1
        case 2:
            return 5
        default:
            return 9
        }
    }
    
    func editEventToReminders(title: String, priority: Int, editTo: String, dueDate: Date, remindDate: Date, edittodo: TodoData){
        // 创建一个谓词以查找具有指定标题的提醒事项
        let predicate = self.eventStore.predicateForReminders(in: nil)
        
        // 指定提醒事项的标题
        let reminderTitleToModify = title

        // 获取提醒事项
        self.eventStore.fetchReminders(matching: predicate) { (reminders) in
            // 遍历提醒事项列表，找到要修改的提醒事项
            if let matchingReminder = reminders?.first(where: { $0.title == reminderTitleToModify }) {
                // 修改提醒事项的属性
                matchingReminder.title = editTo
                matchingReminder.priority = self.setPriority(for: priority)
                edittodo.priority = matchingReminder.priority
                
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
                    try self.eventStore.save(matchingReminder, commit: true)
                    print("提醒事项修改成功")
                } catch {
                    print("提醒事项修改失败: \(error.localizedDescription)")
                }
            } else {
                print("未找到要修改的提醒事项")
                self.addEventToReminders(title: editTo, priority: priority, dueDate: dueDate, remindDate: remindDate, edittodo: edittodo)
            }
        }
    }
}

