//
//  ReminderService.swift
//  DeadLineTodo
//
//  Handles reminders integration
//

import Foundation
import EventKit

final class ReminderService {
    
    static let shared = ReminderService()
    private let eventStore = EKEventStore()
    
    private init() {}
    
    // MARK: - Priority Mapping
    
    private func mapPriority(_ priority: Int) -> Int {
        switch priority {
        case 0: return 0
        case 1: return 1
        case 2: return 5
        default: return 9
        }
    }
    
    // MARK: - Add Reminder
    
    /// 添加提醒事项
    func addReminder(
        title: String,
        priority: Int,
        dueDate: Date,
        remindDate: Date,
        todo: TodoData
    ) {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        reminder.priority = mapPriority(priority)
        todo.priority = reminder.priority
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        reminder.dueDateComponents = components
        reminder.addAlarm(EKAlarm(absoluteDate: remindDate))
        
        do {
            try eventStore.save(reminder, commit: true)
            print("提醒事项添加成功")
        } catch {
            print("提醒事项添加失败: \(error.localizedDescription)")
        }
    }
    
    /// 为任务添加提醒事项
    func addReminder(for todo: TodoData) {
        addReminder(
            title: todo.content,
            priority: todo.priority,
            dueDate: todo.emergencyDate,
            remindDate: todo.emergencyDate,
            todo: todo
        )
    }
    
    // MARK: - Edit Reminder
    
    /// 编辑提醒事项
    func editReminder(
        oldTitle: String,
        newTitle: String,
        priority: Int,
        dueDate: Date,
        remindDate: Date,
        todo: TodoData
    ) {
        let predicate = eventStore.predicateForReminders(in: nil)
        
        eventStore.fetchReminders(matching: predicate) { [weak self] reminders in
            guard let self = self else { return }
            
            if let reminder = reminders?.first(where: { $0.title == oldTitle }) {
                reminder.title = newTitle
                reminder.priority = self.mapPriority(priority)
                
                DispatchQueue.main.async {
                    todo.priority = reminder.priority
                }
                
                let components = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
                reminder.dueDateComponents = components
                
                reminder.alarms?.forEach { reminder.removeAlarm($0) }
                reminder.addAlarm(EKAlarm(absoluteDate: remindDate))
                
                do {
                    try self.eventStore.save(reminder, commit: true)
                    print("提醒事项修改成功")
                } catch {
                    print("提醒事项修改失败: \(error.localizedDescription)")
                }
            } else {
                self.addReminder(
                    title: newTitle,
                    priority: priority,
                    dueDate: dueDate,
                    remindDate: remindDate,
                    todo: todo
                )
            }
        }
    }
    
    // MARK: - Remove Reminder
    
    /// 删除提醒事项
    func removeReminder(title: String) {
        let predicate = eventStore.predicateForReminders(in: nil)
        
        eventStore.fetchReminders(matching: predicate) { [weak self] reminders in
            guard let self = self,
                  let reminder = reminders?.first(where: { $0.title == title }) else { return }
            
            do {
                try self.eventStore.remove(reminder, commit: true)
                print("提醒事项删除成功")
            } catch {
                print("提醒事项删除失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Sync Reminders
    
    /// 同步提醒事项到任务
    func syncReminders(existingTodos: [TodoData]) -> [TodoData] {
        var newTodos: [TodoData] = []
        let predicate = eventStore.predicateForReminders(in: nil)
        
        eventStore.fetchReminders(matching: predicate) { reminders in
            guard let reminders = reminders else { return }
            
            for reminder in reminders where !reminder.isCompleted {
                guard let dueDate = reminder.dueDateComponents?.date,
                      !existingTodos.contains(where: { $0.content == reminder.title }) else { continue }
                
                let todo = TodoData(
                    content: reminder.title ?? "",
                    repeatTime: 0,
                    priority: reminder.priority,
                    endDate: Date(timeIntervalSince1970: dueDate.timeIntervalSince1970 + 7200),
                    addDate: Date(),
                    doneDate: Date(),
                    emergencyDate: dueDate,
                    startDoingDate: Date(),
                    leftTime: 0,
                    needTime: 7200,
                    actualFinishTime: 0,
                    lastTime: 0,
                    initialNeedTime: 0,
                    Day: 0,
                    Hour: 2,
                    Min: 0,
                    Sec: 0,
                    todo: true,
                    done: false,
                    emergency: false,
                    doing: false,
                    offset: 0,
                    lastoffset: 0,
                    score: 0,
                    times: 0
                )
                newTodos.append(todo)
            }
        }
        
        return newTodos
    }
    
    // MARK: - Permission
    
    /// 请求提醒事项权限
    func requestPermission() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        
        switch status {
        case .notDetermined:
            eventStore.requestFullAccessToReminders { success, error in
                if let error = error {
                    print("提醒事项权限请求失败: \(error.localizedDescription)")
                }
            }
        default:
            break
        }
    }
}
