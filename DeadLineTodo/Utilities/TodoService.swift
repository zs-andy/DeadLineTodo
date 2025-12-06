//
//  TodoService.swift
//  DeadLineTodo
//
//  Core business logic for todo operations
//

import Foundation
import SwiftData
import SwiftUI
import WidgetKit

// MARK: - Todo Service

final class TodoService {
    
    static let shared = TodoService()
    private init() {}
    
    // MARK: - Time Calculations
    
    /// 计算剩余时间
    func getLeftTime(for todo: TodoData) -> TimeInterval {
        let needTime = TimeInterval.from(days: todo.Day, hours: todo.Hour, minutes: todo.Min, seconds: todo.Sec)
        return max(todo.endDate.timeIntervalSince1970 - Date().timeIntervalSince1970 - needTime, 0)
    }
    
    /// 计算所需时间
    func getNeedTime(days: Int, hours: Int, minutes: Int) -> TimeInterval {
        TimeInterval.from(days: days, hours: hours, minutes: minutes)
    }
    
    /// 计算进度条宽度
    func getProgressWidth(for todo: TodoData, totalWidth: CGFloat) -> CGFloat {
        let needTime = todo.needTime - todo.actualFinishTime
        let total = todo.endDate.timeIntervalSince1970 - Date().timeIntervalSince1970
        guard total > 0 else { return totalWidth }
        let size = (needTime / total) * Double(totalWidth)
        return min(max(CGFloat(size), 0), totalWidth)
    }
    
    /// 计算紧急线位置
    func getEmergencyLinePosition(for todo: TodoData, totalWidth: CGFloat) -> CGFloat {
        let total = todo.endDate.timeIntervalSince1970 - Date().timeIntervalSince1970
        guard total > 0 else { return 0 }
        let position = (todo.emergencyDate.timeIntervalSince1970 - Date().timeIntervalSince1970) / total * Double(totalWidth)
        return CGFloat(position)
    }
    
    // MARK: - Score Calculation
    
    /// 计算单个任务效率分数
    func calculateScore(for todo: TodoData) -> Int {
        let needTime = TimeInterval.from(days: todo.Day, hours: todo.Hour, minutes: todo.Min, seconds: todo.Sec)
        let totalTime = todo.endDate.timeIntervalSince1970 - todo.addDate.timeIntervalSince1970
        
        guard totalTime > 0 else { return 0 }
        
        // 时间分数 (30%)
        var timeScore = (todo.endDate.timeIntervalSince1970 - todo.doneDate.timeIntervalSince1970 - needTime) / totalTime
        timeScore = min(max(timeScore, 0), 1)
        
        // 效率分数 (70%)
        var efficiencyScore: Double = 100
        if todo.needTime < todo.actualFinishTime {
            let overtime = (todo.actualFinishTime - todo.needTime) / todo.needTime
            efficiencyScore = overtime >= 1 ? 0 : 100 - overtime * 100
        }
        
        return Int(timeScore * 100 * 0.3 + efficiencyScore * 0.7)
    }
    
    /// 计算周效率分数
    func calculateWeeklyScore(from todos: [TodoData]) -> Int {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }
        
        let weekTodos = todos.filter { $0.done && $0.doneDate > weekStart }
        guard !weekTodos.isEmpty else { return 0 }
        
        let totalScore = weekTodos.reduce(0) { $0 + $1.score }
        return totalScore / weekTodos.count
    }
    
    // MARK: - Repeat Task Logic
    
    private let periodSeconds: [TimeInterval] = [86400, 604800, 2592000] // day, week, month
    
    /// 计算重复任务的下一个周期
    func calculateNextRepeat(for todo: inout TodoData, repeatTime: Int) {
        guard repeatTime > 0, repeatTime <= periodSeconds.count else { return }
        
        let period = periodSeconds[repeatTime - 1]
        
        todo.endDate = Date(timeIntervalSince1970: todo.endDate.timeIntervalSince1970 + period)
        todo.emergencyDate = Date(timeIntervalSince1970: todo.emergencyDate.timeIntervalSince1970 + period)
        todo.addDate = todo.emergencyDate.startOfDay
        
        // 确保日期在未来
        while todo.emergencyDate < Date() {
            todo.endDate = Date(timeIntervalSince1970: todo.endDate.timeIntervalSince1970 + period)
            todo.emergencyDate = Date(timeIntervalSince1970: todo.emergencyDate.timeIntervalSince1970 + period)
            todo.addDate = todo.emergencyDate.startOfDay
        }
    }
    
    /// 创建重复任务
    func createRepeatTodo(from original: TodoData, modelContext: ModelContext) -> TodoData {
        let decomposed = original.initialNeedTime.decomposed
        
        var newTodo = TodoData(
            content: original.content,
            repeatTime: original.repeatTime,
            priority: original.priority,
            endDate: original.endDate,
            addDate: Date(),
            doneDate: Date(),
            emergencyDate: original.emergencyDate,
            startDoingDate: Date(),
            leftTime: 0,
            needTime: original.initialNeedTime,
            actualFinishTime: 0,
            lastTime: 0,
            initialNeedTime: original.initialNeedTime,
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
            times: original.times + 1
        )
        
        calculateNextRepeat(for: &newTodo, repeatTime: original.repeatTime)
        modelContext.insert(newTodo)
        
        return newTodo
    }
    
    // MARK: - Complete Task
    
    /// 完成任务
    func completeTodo(
        _ todo: TodoData,
        doneDate: Date = Date(),
        emergencyNum: inout Int,
        modelContext: ModelContext,
        notificationService: NotificationService,
        reminderService: ReminderService,
        calendarService: CalendarService
    ) -> Bool {
        // 检查任务是否已开始
        guard todo.addDate <= Date() else { return false }
        
        // 更新紧急数量
        if todo.emergency { emergencyNum -= 1 }
        
        // 如果正在进行，停止计时
        if todo.doing {
            todo.doing = false
            notificationService.cancelNotification(id: todo.id.uuidString + "4")
            todo.lastTime = todo.actualFinishTime
            updateRemainingTime(for: todo)
        }
        
        // 取消所有通知
        notificationService.cancelAllNotifications(for: todo)
        reminderService.removeReminder(title: todo.content)
        
        // 更新任务状态
        todo.doneDate = doneDate
        todo.score = calculateScore(for: todo)
        todo.offset = 0
        todo.todo = false
        todo.emergency = false
        todo.done = true
        
        // 处理重复任务
        if todo.repeatTime != 0 {
            let newTodo = createRepeatTodo(from: todo, modelContext: modelContext)
            notificationService.sendNotifications(for: newTodo)
            reminderService.addReminder(for: newTodo)
            calendarService.addEvent(for: newTodo)
        }
        
        WidgetCenter.shared.reloadAllTimelines()
        return true
    }
    
    /// 更新剩余时间
    private func updateRemainingTime(for todo: TodoData) {
        if todo.actualFinishTime < todo.needTime {
            let remaining = (todo.needTime - todo.actualFinishTime).decomposed
            todo.Day = remaining.days
            todo.Hour = remaining.hours
            todo.Min = remaining.minutes
            todo.Sec = remaining.seconds
        } else {
            todo.Day = 0
            todo.Hour = 0
            todo.Min = 0
            todo.Sec = 0
        }
    }
    
    // MARK: - Toggle Doing State
    
    /// 切换任务进行状态
    func toggleDoing(
        _ todo: TodoData,
        notificationService: NotificationService
    ) -> Bool {
        guard todo.addDate <= Date() else { return false }
        
        if todo.doing {
            // 暂停
            todo.doing = false
            notificationService.cancelNotification(id: todo.id.uuidString + "4")
            todo.lastTime = todo.actualFinishTime
            updateRemainingTime(for: todo)
            notificationService.sendDeadlineNotification(for: todo)
        } else {
            // 开始
            todo.doing = true
            todo.startDoingDate = Date()
            todo.actualFinishTime = 0
            notificationService.sendOvertimeNotification(for: todo)
            notificationService.cancelNotification(id: todo.id.uuidString + "1")
        }
        
        return true
    }
    
    // MARK: - Refresh Time
    
    /// 刷新任务时间状态
    func refreshTime(
        for todo: TodoData,
        emergencyNum: inout Int,
        isEditing: Bool
    ) {
        guard !todo.done, !isEditing else { return }
        
        // 更新实际完成时间
        if todo.doing {
            todo.actualFinishTime = todo.lastTime + Date().timeIntervalSince1970 - todo.startDoingDate.timeIntervalSince1970
        }
        
        // 更新剩余时间
        todo.leftTime = getLeftTime(for: todo)
        
        // 更新紧急状态
        let wasEmergency = todo.emergency
        todo.emergency = todo.leftTime <= 60
        
        if todo.emergency != wasEmergency {
            withAnimation {
                emergencyNum += todo.emergency ? 1 : -1
            }
        }
    }
}
