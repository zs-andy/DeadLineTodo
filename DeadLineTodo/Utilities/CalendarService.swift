//
//  CalendarService.swift
//  DeadLineTodo
//
//  Handles calendar integration
//

import Foundation
import EventKit

final class CalendarService {
    
    static let shared = CalendarService()
    private let eventStore = EKEventStore()
    
    private init() {}
    
    // MARK: - Add Event
    
    /// 添加日历事件
    func addEvent(title: String, startDate: Date, endDate: Date) {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.calendar = eventStore.defaultCalendarForNewEvents
        event.startDate = startDate
        event.endDate = endDate
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
        let duration = TimeInterval.from(days: todo.Day, hours: todo.Hour, minutes: todo.Min)
        let endDate = Date(timeIntervalSince1970: todo.emergencyDate.timeIntervalSince1970 + duration)
        addEvent(title: todo.content, startDate: todo.emergencyDate, endDate: endDate)
    }
    
    // MARK: - Edit Event
    
    /// 编辑日历事件
    func editEvent(oldTitle: String, newTitle: String, startDate: Date, endDate: Date) {
        let predicate = eventStore.predicateForEvents(
            withStart: Date(),
            end: Date().addingTimeInterval(31 * 86400),
            calendars: nil
        )
        
        let events = eventStore.events(matching: predicate)
        
        if let event = events.first(where: { $0.title == oldTitle }) {
            event.title = newTitle
            event.startDate = startDate
            event.endDate = endDate
            
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
            addEvent(title: newTitle, startDate: startDate, endDate: endDate)
        }
    }
    
    // MARK: - Delete Event
    
    /// 删除日历事件
    func deleteEvent(title: String) {
        let predicate = eventStore.predicateForEvents(
            withStart: Date(),
            end: Date().addingTimeInterval(31 * 86400),
            calendars: nil
        )
        
        let events = eventStore.events(matching: predicate)
        
        if let event = events.first(where: { $0.title == title }) {
            do {
                try eventStore.remove(event, span: .thisEvent)
                print("日历事件删除成功")
            } catch {
                print("日历事件删除失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Sync Events
    
    /// 同步日历事件到任务
    func syncEvents(
        selectedCalendars: [String],
        existingTodos: [TodoData],
        modelContext: Any
    ) -> [TodoData] {
        var newTodos: [TodoData] = []
        let calendars = eventStore.calendars(for: .event)
        
        for calendar in calendars where selectedCalendars.contains(calendar.title) {
            let predicate = eventStore.predicateForEvents(
                withStart: Date(),
                end: Date().addingTimeInterval(31 * 7 * 86400),
                calendars: [calendar]
            )
            
            let events = eventStore.events(matching: predicate)
            
            for event in events {
                guard !existingTodos.contains(where: { $0.content == event.title }) else { continue }
                
                let needTime = event.endDate.timeIntervalSince1970 - event.startDate.timeIntervalSince1970
                let decomposed = needTime.decomposed
                
                let todo = TodoData(
                    content: event.title,
                    repeatTime: 0,
                    priority: 0,
                    endDate: event.endDate,
                    addDate: Date(),
                    doneDate: Date(),
                    emergencyDate: event.startDate,
                    startDoingDate: Date(),
                    leftTime: 0,
                    needTime: needTime,
                    actualFinishTime: 0,
                    lastTime: 0,
                    initialNeedTime: needTime,
                    Day: decomposed.days,
                    Hour: decomposed.hours,
                    Min: decomposed.minutes,
                    Sec: decomposed.seconds,
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
