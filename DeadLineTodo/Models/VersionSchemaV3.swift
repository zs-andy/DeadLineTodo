//
//  VersionSchemaV3.swift
//  DeadLineTodo
//
//  Created by Andy on 2024/2/20.
//

import Foundation
import SwiftData

enum TodoDataSchemaV3: @preconcurrency VersionedSchema {
    static var models: [any PersistentModel.Type]{
        [TodoData.self, UserSetting.self]
    }
    @MainActor static var versionIdentifier: Schema.Version = .init(2, 1, 0)
}

extension TodoDataSchemaV3 {
    @Model
    class TodoData: Identifiable{
        var id = UUID()
        
        var content: String
        var priority: Int = 0
        
        var endDate: Date
        var addDate: Date
        var doneDate: Date
        var emergencyDate: Date = Date()
        var startDoingDate: Date = Date()
        
        var leftTime: TimeInterval
        var needTime: TimeInterval = 0
        var actualFinishTime: TimeInterval = 0
        var lastTime: TimeInterval = 0
        
        var Day: Int
        var Hour: Int
        var Min: Int
        var Sec: Int
        
        var todo: Bool
        var done: Bool
        var emergency: Bool
        var doing: Bool = false
        
        var offset: CGFloat
        
        var score: Int
        
        init(content: String, priority: Int, endDate: Date, addDate: Date, doneDate: Date, emergencyDate: Date, startDoingDate: Date, leftTime: TimeInterval, needTime: TimeInterval, actualFinishTime: TimeInterval, lastTime: TimeInterval, Day: Int, Hour: Int, Min: Int, Sec: Int, todo: Bool, done: Bool, emergency: Bool, doing: Bool, offset: CGFloat, score: Int) {
            self.content = content
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
            self.Day = Day
            self.Hour = Hour
            self.Min = Min
            self.Sec = Sec
            self.todo = todo
            self.done = done
            self.emergency = emergency
            self.doing = doing
            self.offset = offset
            self.score = score
        }
    }

    @Model
    class UserSetting: Identifiable {
        var frequency: Int = 1
        init(frequency: Int) {
            self.frequency = frequency
        }
    }
}
