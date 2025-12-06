//
//  TodoData.swift
//  DeadLineTodo
//
//  Refactored with modern Swift and MVVM architecture
//

import Foundation
import SwiftData

// MARK: - Current Schema (V9)

enum TodoDataSchemaV9: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [TodoData.self, UserSetting.self]
    }
    
    @MainActor
    static var versionIdentifier: Schema.Version = .init(3, 1, 0)
}

extension TodoDataSchemaV9 {
    
    @Model
    final class TodoData: Identifiable {
        var id = UUID()
        
        // MARK: - Content
        var content: String = ""
        var repeatTime: Int = 0
        var priority: Int = 0
        
        // MARK: - Dates
        var endDate: Date = Date()
        var addDate: Date = Date()
        var doneDate: Date = Date()
        var emergencyDate: Date = Date()
        var startDoingDate: Date = Date()
        
        // MARK: - Time Tracking
        var leftTime: TimeInterval = 0
        var needTime: TimeInterval = 0
        var actualFinishTime: TimeInterval = 0
        var lastTime: TimeInterval = 0
        var initialNeedTime: TimeInterval = 0
        
        // MARK: - Duration Components
        var Day: Int = 0
        var Hour: Int = 2
        var Min: Int = 0
        var Sec: Int = 0
        
        // MARK: - Status Flags
        var todo: Bool = false
        var done: Bool = false
        var emergency: Bool = false
        var doing: Bool = false
        
        // MARK: - UI State
        var offset: CGFloat = 0
        var lastoffset: CGFloat = 0
        
        // MARK: - Statistics
        var score: Int = 100
        var times: Int = 0
        
        init(
            content: String,
            repeatTime: Int,
            priority: Int,
            endDate: Date,
            addDate: Date,
            doneDate: Date,
            emergencyDate: Date,
            startDoingDate: Date,
            leftTime: TimeInterval,
            needTime: TimeInterval,
            actualFinishTime: TimeInterval,
            lastTime: TimeInterval,
            initialNeedTime: TimeInterval,
            Day: Int,
            Hour: Int,
            Min: Int,
            Sec: Int,
            todo: Bool,
            done: Bool,
            emergency: Bool,
            doing: Bool,
            offset: CGFloat,
            lastoffset: CGFloat,
            score: Int,
            times: Int
        ) {
            self.content = content
            self.repeatTime = repeatTime
            self.priority = priority
            self.endDate = endDate
            self.addDate = addDate
            self.doneDate = doneDate
            self.emergencyDate = emergencyDate
            self.startDoingDate = startDoingDate
            self.leftTime = leftTime
            self.needTime = needTime
            self.actualFinishTime = actualFinishTime
            self.lastTime = lastTime
            self.initialNeedTime = initialNeedTime
            self.Day = Day
            self.Hour = Hour
            self.Min = Min
            self.Sec = Sec
            self.todo = todo
            self.done = done
            self.emergency = emergency
            self.doing = doing
            self.offset = offset
            self.lastoffset = lastoffset
            self.score = score
            self.times = times
        }
    }
    
    @Model
    final class UserSetting: Identifiable {
        var frequency: Int = 1
        var reminder: Bool = true
        var hasPurchased: Bool = false
        var calendar: Bool = false
        var selectedOptions: [String] = []
        
        init(
            frequency: Int,
            reminder: Bool,
            hasPurchased: Bool,
            calendar: Bool,
            selectedOptions: [String]
        ) {
            self.frequency = frequency
            self.reminder = reminder
            self.hasPurchased = hasPurchased
            self.calendar = calendar
            self.selectedOptions = selectedOptions
        }
    }
}

// MARK: - Type Aliases
// Note: typealias definitions are in DeadLineTodoApp.swift for main app
// and DeadLineTodoWidget.swift for widget extension to avoid conflicts
