//
//  ReminderService.swift
//  DeadLineTodo
//
//  Handles reminders integration
//

import Foundation
import EventKit

/// 用于在提醒事项notes中标识来源的前缀
private let kDeadLineTodoPrefix = "[DeadLineTodo:"

final class ReminderService {
    
    static let shared = ReminderService()
    private let eventStore = EKEventStore()
    
    private init() {}
    
    // MARK: - UUID Helpers
    
    /// 从notes中提取TodoData的UUID
    private func extractTodoId(from notes: String?) -> UUID? {
        guard let notes = notes,
              let startRange = notes.range(of: kDeadLineTodoPrefix),
              let endRange = notes.range(of: "]", range: startRange.upperBound..<notes.endIndex) else {
            return nil
        }
        let uuidString = String(notes[startRange.upperBound..<endRange.lowerBound])
        return UUID(uuidString: uuidString)
    }
    
    /// 生成包含UUID的notes
    private func generateNotes(for todoId: UUID) -> String {
        "\(kDeadLineTodoPrefix)\(todoId.uuidString)]"
    }
    
    // MARK: - Priority Mapping
    
    private func mapPriority(_ priority: Int) -> Int {
        switch priority {
        case 0: return 0
        case 1: return 1
        case 2: return 5
        default: return 9
        }
    }
    
    private func reversePriority(_ priority: Int) -> Int {
        switch priority {
        case 0: return 0
        case 1: return 1
        case 5: return 2
        case 9: return 3
        default: return 0
        }
    }
    
    // MARK: - Find Reminder
    
    /// 通过TodoData的UUID查找提醒事项
    private func findReminder(byTodoId todoId: UUID, completion: @escaping (EKReminder?) -> Void) {
        let predicate = eventStore.predicateForReminders(in: nil)
        eventStore.fetchReminders(matching: predicate) { [weak self] reminders in
            let reminder = reminders?.first { self?.extractTodoId(from: $0.notes) == todoId }
            DispatchQueue.main.async {
                completion(reminder)
            }
        }
    }
    
    /// 通过标题查找提醒事项（兼容旧数据）
    private func findReminder(byTitle title: String, completion: @escaping (EKReminder?) -> Void) {
        let predicate = eventStore.predicateForReminders(in: nil)
        eventStore.fetchReminders(matching: predicate) { reminders in
            let reminder = reminders?.first { $0.title == title }
            DispatchQueue.main.async {
                completion(reminder)
            }
        }
    }
    
    /// 检查提醒事项是否存在
    func reminderExists(todoId: UUID, completion: @escaping (Bool) -> Void) {
        findReminder(byTodoId: todoId) { reminder in
            completion(reminder != nil)
        }
    }
    
    // MARK: - Add Reminder
    
    /// 添加提醒事项（带UUID标识）
    func addReminder(
        title: String,
        priority: Int,
        dueDate: Date,
        remindDate: Date,
        todo: TodoData
    ) {
        // 先检查是否已存在
        findReminder(byTodoId: todo.id) { [weak self] existingReminder in
            guard let self = self else { return }
            
            if existingReminder != nil {
                print("提醒事项已存在，跳过添加")
                return
            }
            
            let reminder = EKReminder(eventStore: self.eventStore)
            reminder.title = title
            reminder.calendar = self.eventStore.defaultCalendarForNewReminders()
            reminder.priority = self.mapPriority(priority)
            reminder.notes = self.generateNotes(for: todo.id)
            
            DispatchQueue.main.async {
                todo.priority = reminder.priority
            }
            
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
            reminder.dueDateComponents = components
            reminder.addAlarm(EKAlarm(absoluteDate: remindDate))
            
            do {
                try self.eventStore.save(reminder, commit: true)
                print("提醒事项添加成功")
            } catch {
                print("提醒事项添加失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 为任务添加提醒事项
    func addReminder(for todo: TodoData) {
        addReminder(
            title: todo.content,
            priority: reversePriority(todo.priority),
            dueDate: todo.emergencyDate,
            remindDate: todo.emergencyDate,
            todo: todo
        )
    }
    
    // MARK: - Edit Reminder
    
    /// 编辑提醒事项（优先通过UUID查找）
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
            guard let self = self, let reminders = reminders else { return }
            
            // 优先通过UUID查找
            var reminder = reminders.first { self.extractTodoId(from: $0.notes) == todo.id }
            
            // 如果找不到，尝试通过旧标题查找（兼容旧数据）
            if reminder == nil {
                reminder = reminders.first { $0.title == oldTitle }
            }
            
            if let reminder = reminder {
                reminder.title = newTitle
                reminder.priority = self.mapPriority(priority)
                
                // 确保notes包含UUID
                if self.extractTodoId(from: reminder.notes) == nil {
                    reminder.notes = self.generateNotes(for: todo.id)
                }
                
                DispatchQueue.main.async {
                    todo.priority = reminder.priority
                }
                
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
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
                // 提醒事项不存在，重新创建
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
    
    /// 删除提醒事项（优先通过UUID）
    func removeReminder(todoId: UUID, title: String) {
        let predicate = eventStore.predicateForReminders(in: nil)
        
        eventStore.fetchReminders(matching: predicate) { [weak self] reminders in
            guard let self = self, let reminders = reminders else { return }
            
            // 优先通过UUID查找
            var reminder = reminders.first { self.extractTodoId(from: $0.notes) == todoId }
            
            // 如果找不到，尝试通过标题查找
            if reminder == nil {
                reminder = reminders.first { $0.title == title }
            }
            
            guard let reminder = reminder else {
                print("提醒事项不存在，无需删除")
                return
            }
            
            do {
                try self.eventStore.remove(reminder, commit: true)
                print("提醒事项删除成功")
            } catch {
                print("提醒事项删除失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 删除提醒事项（旧接口，兼容）
    func removeReminder(title: String) {
        let predicate = eventStore.predicateForReminders(in: nil)
        eventStore.fetchReminders(matching: predicate) { [weak self] reminders in
            guard let self = self,
                  let reminder = reminders?.first(where: { $0.title == title }) else { return }
            try? self.eventStore.remove(reminder, commit: true)
        }
    }
    
    /// 标记提醒事项为已完成
    func completeReminder(title: String) {
        let predicate = eventStore.predicateForReminders(in: nil)
        
        eventStore.fetchReminders(matching: predicate) { [weak self] reminders in
            guard let self = self,
                  let reminder = reminders?.first(where: { $0.title == title }) else { return }
            
            reminder.isCompleted = true
            reminder.completionDate = Date()
            
            do {
                try self.eventStore.save(reminder, commit: true)
                print("提醒事项标记完成成功")
            } catch {
                print("提醒事项标记完成失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Sync Reminders
    
    /// 同步提醒事项到任务（单向：从提醒事项到App）
    /// 只同步App创建的提醒事项（包含DeadLineTodo UUID标识的提醒）
    /// 不同步外部创建的提醒事项
    func syncReminders(existingTodos: [TodoData], completion: @escaping ([TodoData]) -> Void) {
        // 不再从提醒事项同步创建新任务
        // 只有App创建的提醒才会有UUID标识，外部提醒不会被同步
        DispatchQueue.main.async {
            completion([])
        }
    }
    
    /// 从外部提醒事项同步修改到App内部任务
    /// 检查App创建的提醒事项是否在外部被修改，并更新对应的TodoData
    func syncExternalChanges(existingTodos: [TodoData], completion: @escaping () -> Void) {
        let predicate = eventStore.predicateForReminders(in: nil)
        
        eventStore.fetchReminders(matching: predicate) { [weak self] reminders in
            guard let self = self, let reminders = reminders else {
                DispatchQueue.main.async { completion() }
                return
            }
            
            DispatchQueue.main.async {
                for reminder in reminders {
                    // 只处理包含UUID标识的提醒（App创建的）
                    guard let todoId = self.extractTodoId(from: reminder.notes),
                          let reminderTitle = reminder.title,
                          let dueDate = reminder.dueDateComponents?.date else { continue }
                    
                    // 查找对应的任务
                    guard let todo = existingTodos.first(where: { $0.id == todoId }) else { continue }
                    
                    // 检查是否有变化，如果有则更新任务
                    var hasChanges = false
                    
                    if todo.content != reminderTitle {
                        todo.content = reminderTitle
                        hasChanges = true
                    }
                    
                    // 比较时间（允许1秒误差）
                    if abs(todo.emergencyDate.timeIntervalSince1970 - dueDate.timeIntervalSince1970) > 1 {
                        todo.emergencyDate = dueDate
                        todo.endDate = Date(timeIntervalSince1970: dueDate.timeIntervalSince1970 + todo.needTime)
                        hasChanges = true
                    }
                    
                    // 同步优先级
                    if todo.priority != reminder.priority {
                        todo.priority = reminder.priority
                        hasChanges = true
                    }
                    
                    // 同步完成状态
                    if reminder.isCompleted && !todo.done {
                        todo.done = true
                        todo.todo = false
                        todo.doneDate = reminder.completionDate ?? Date()
                        hasChanges = true
                    }
                    
                    if hasChanges {
                        print("提醒事项外部修改已同步: \(reminderTitle)")
                    }
                }
                
                completion()
            }
        }
    }
    
    /// 同步提醒事项到任务（同步版本，用于兼容旧代码）
    func syncReminders(existingTodos: [TodoData]) -> [TodoData] {
        // 这个方法保留用于兼容，但更新操作会在回调中异步完成
        var result: [TodoData] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        syncReminders(existingTodos: existingTodos) { newTodos in
            result = newTodos
            semaphore.signal()
        }
        
        // 等待最多2秒
        _ = semaphore.wait(timeout: .now() + 2)
        return result
    }
    
    /// 检查并处理外部删除的提醒事项
    /// 返回被外部删除的任务标题列表
    func checkDeletedReminders(existingTodos: [TodoData], completion: @escaping ([String]) -> Void) {
        var deletedTitles: [String] = []
        let predicate = eventStore.predicateForReminders(in: nil)
        
        // 只检查未完成的任务
        let activeTodos = existingTodos.filter { $0.todo && !$0.done }
        
        eventStore.fetchReminders(matching: predicate) { reminders in
            let reminderTitles = Set(reminders?.compactMap { $0.title } ?? [])
            
            for todo in activeTodos {
                if !reminderTitles.contains(todo.content) {
                    deletedTitles.append(todo.content)
                }
            }
            
            DispatchQueue.main.async {
                completion(deletedTitles)
            }
        }
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
