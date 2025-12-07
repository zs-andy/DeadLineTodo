//
//  CalendarService.swift
//  DeadLineTodo
//
//  Handles calendar integration
//

import Foundation
import EventKit

/// 用于在日历事件notes中标识来源的前缀
private let kDeadLineTodoPrefix = "[DeadLineTodo:"

final class CalendarService {
    
    static let shared = CalendarService()
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
    
    // MARK: - Add Event
    
    /// 添加日历事件（带UUID标识）
    func addEvent(title: String, startDate: Date, endDate: Date, todoId: UUID) {
        // 检查是否已存在该任务的事件
        if findEvent(byTodoId: todoId) != nil {
            print("日历事件已存在，跳过添加")
            return
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.calendar = eventStore.defaultCalendarForNewEvents
        event.startDate = startDate
        event.endDate = endDate
        event.notes = generateNotes(for: todoId)
        event.addAlarm(EKAlarm(absoluteDate: startDate))
        
        do {
            try eventStore.save(event, span: .thisEvent)
            print("日历事件添加成功")
        } catch {
            print("日历事件添加失败: \(error.localizedDescription)")
        }
    }
    
    /// 为任务添加日历事件
    func addEvent(for todo: TodoData) {
        addEvent(title: todo.content, startDate: todo.emergencyDate, endDate: todo.endDate, todoId: todo.id)
    }
    
    // MARK: - Find Event
    
    /// 通过TodoData的UUID查找日历事件
    private func findEvent(byTodoId todoId: UUID) -> EKEvent? {
        let predicate = eventStore.predicateForEvents(
            withStart: Date().addingTimeInterval(-365 * 86400),
            end: Date().addingTimeInterval(365 * 86400),
            calendars: nil
        )
        let events = eventStore.events(matching: predicate)
        return events.first { extractTodoId(from: $0.notes) == todoId }
    }
    
    /// 通过标题查找日历事件（兼容旧数据）
    private func findEvent(byTitle title: String) -> EKEvent? {
        let predicate = eventStore.predicateForEvents(
            withStart: Date().addingTimeInterval(-365 * 86400),
            end: Date().addingTimeInterval(365 * 86400),
            calendars: nil
        )
        let events = eventStore.events(matching: predicate)
        return events.first { $0.title == title }
    }
    
    // MARK: - Edit Event
    
    /// 编辑日历事件（优先通过UUID查找）
    func editEvent(todoId: UUID, oldTitle: String, newTitle: String, startDate: Date, endDate: Date) {
        // 优先通过UUID查找
        var event = findEvent(byTodoId: todoId)
        
        // 如果找不到，尝试通过旧标题查找（兼容旧数据）
        if event == nil {
            event = findEvent(byTitle: oldTitle)
        }
        
        if let event = event {
            event.title = newTitle
            event.startDate = startDate
            event.endDate = endDate
            
            // 确保notes包含UUID
            if extractTodoId(from: event.notes) == nil {
                event.notes = generateNotes(for: todoId)
            }
            
            // 更新提醒
            event.alarms?.forEach { event.removeAlarm($0) }
            event.addAlarm(EKAlarm(absoluteDate: startDate))
            
            do {
                try eventStore.save(event, span: .thisEvent)
                print("日历事件修改成功")
            } catch {
                print("日历事件修改失败: \(error.localizedDescription)")
            }
        } else {
            // 事件不存在，重新创建
            addEvent(title: newTitle, startDate: startDate, endDate: endDate, todoId: todoId)
        }
    }
    
    /// 编辑日历事件（旧接口，兼容）
    func editEvent(oldTitle: String, newTitle: String, startDate: Date, endDate: Date) {
        if let event = findEvent(byTitle: oldTitle) {
            event.title = newTitle
            event.startDate = startDate
            event.endDate = endDate
            event.alarms?.forEach { event.removeAlarm($0) }
            event.addAlarm(EKAlarm(absoluteDate: startDate))
            
            do {
                try eventStore.save(event, span: .thisEvent)
            } catch {
                print("日历事件修改失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Delete Event
    
    /// 删除日历事件（优先通过UUID）
    func deleteEvent(todoId: UUID, title: String) {
        var event = findEvent(byTodoId: todoId)
        if event == nil {
            event = findEvent(byTitle: title)
        }
        
        guard let event = event else {
            print("日历事件不存在，无需删除")
            return
        }
        
        do {
            try eventStore.remove(event, span: .thisEvent)
            print("日历事件删除成功")
        } catch {
            print("日历事件删除失败: \(error.localizedDescription)")
        }
    }
    
    /// 删除日历事件（旧接口，兼容）
    func deleteEvent(title: String) {
        guard let event = findEvent(byTitle: title) else { return }
        try? eventStore.remove(event, span: .thisEvent)
    }
    
    // MARK: - Check Event Exists
    
    /// 检查日历事件是否存在
    func eventExists(todoId: UUID) -> Bool {
        findEvent(byTodoId: todoId) != nil
    }
    
    // MARK: - Sync Events
    
    /// 同步日历事件到任务（单向：从日历到App）
    /// 只同步App创建的事件（包含DeadLineTodo UUID标识的事件）
    /// 不同步外部创建的日历事件
    func syncEvents(
        selectedCalendars: [String],
        existingTodos: [TodoData],
        modelContext: Any
    ) -> [TodoData] {
        // 不再从日历同步创建新任务
        // 只有App创建的事件才会有UUID标识，外部事件不会被同步
        return []
    }
    
    /// 从外部日历同步修改到App内部任务
    /// 检查App创建的日历事件是否在外部被修改，并更新对应的TodoData
    func syncExternalChanges(existingTodos: [TodoData]) {
        let predicate = eventStore.predicateForEvents(
            withStart: Date().addingTimeInterval(-365 * 86400),
            end: Date().addingTimeInterval(365 * 86400),
            calendars: nil
        )
        let events = eventStore.events(matching: predicate)
        
        for event in events {
            // 只处理包含UUID标识的事件（App创建的）
            guard let todoId = extractTodoId(from: event.notes),
                  let eventTitle = event.title,
                  let eventStartDate = event.startDate,
                  let eventEndDate = event.endDate else { continue }
            
            // 查找对应的任务
            guard let todo = existingTodos.first(where: { $0.id == todoId }) else { continue }
            
            // 检查是否有变化，如果有则更新任务
            var hasChanges = false
            
            if todo.content != eventTitle {
                todo.content = eventTitle
                hasChanges = true
            }
            
            // 比较时间（允许1秒误差）
            if abs(todo.emergencyDate.timeIntervalSince1970 - eventStartDate.timeIntervalSince1970) > 1 {
                todo.emergencyDate = eventStartDate
                hasChanges = true
            }
            
            if abs(todo.endDate.timeIntervalSince1970 - eventEndDate.timeIntervalSince1970) > 1 {
                todo.endDate = eventEndDate
                // 更新needTime
                let needTime = eventEndDate.timeIntervalSince1970 - eventStartDate.timeIntervalSince1970
                todo.needTime = needTime
                todo.initialNeedTime = needTime
                let decomposed = needTime.decomposed
                todo.Day = decomposed.days
                todo.Hour = decomposed.hours
                todo.Min = decomposed.minutes
                todo.Sec = decomposed.seconds
                hasChanges = true
            }
            
            if hasChanges {
                print("日历事件外部修改已同步: \(eventTitle)")
            }
        }
    }
    
    /// 检查并处理外部删除的日历事件
    /// 返回被外部删除的任务ID列表
    func checkDeletedEvents(existingTodos: [TodoData], selectedCalendars: [String]) -> [UUID] {
        var deletedIds: [UUID] = []
        
        // 只检查未完成的任务
        let activeTodos = existingTodos.filter { $0.todo && !$0.done }
        
        for todo in activeTodos {
            // 检查日历中是否还存在该事件
            if !eventExists(todoId: todo.id) {
                deletedIds.append(todo.id)
            }
        }
        
        return deletedIds
    }
    
    // MARK: - Get Calendars
    
    /// 获取所有日历
    func getCalendars() -> [(title: String, color: CGColor)] {
        eventStore.calendars(for: .event).map { ($0.title, $0.cgColor) }
    }
    
    // MARK: - Permission
    
    /// 请求日历权限
    func requestPermission() {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .notDetermined:
            eventStore.requestFullAccessToEvents { success, error in
                if let error = error {
                    print("日历权限请求失败: \(error.localizedDescription)")
                }
            }
        default:
            break
        }
    }
}
