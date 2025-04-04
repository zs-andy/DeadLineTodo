//
//  VersionSchemaV1.swift
//  DeadLineTodo
//
//  Created by Andy on 2024/2/15.
//

import Foundation
import SwiftData

enum TodoDataSchemaV2: @preconcurrency VersionedSchema {
    static var models: [any PersistentModel.Type]{
        [TodoData.self, UserSetting.self]
    }
    @MainActor static var versionIdentifier: Schema.Version = .init(1, 4, 4)
}

extension TodoDataSchemaV2 {
    @Model
    class TodoData: Identifiable{
        var id = UUID()
        
        var content: String
        var priority: Int = 0
        
        var endDate: Date
        var addDate: Date
        var doneDate: Date
        var emergencyDate: Date = Date()
        
        var leftTime: TimeInterval
        
        var Day: Int
        var Hour: Int
        var Min: Int
        var Sec: Int
        
        var todo: Bool
        var done: Bool
        var emergency: Bool
        
        var offset: CGFloat
        
        var score: Int
        
        init(content: String, priority: Int, endDate: Date, addDate: Date, doneDate: Date, emergencyDate: Date, leftTime: TimeInterval, Day: Int, Hour: Int, Min: Int, Sec: Int, todo: Bool, done: Bool, emergency: Bool, offset: CGFloat, score: Int) {
            self.content = content
            self.priority = priority
            self.endDate = endDate
            self.addDate = addDate
            self.doneDate = doneDate
            self.emergencyDate = emergencyDate
            self.leftTime = leftTime
            self.Day = Day
            self.Hour = Hour
            self.Min = Min
            self.Sec = Sec
            self.todo = todo
            self.done = done
            self.emergency = emergency
            self.offset = offset
            self.score = score
        }
    }

    @Model
    class UserSetting: Identifiable {
        var frequency: Int = 2
        init(frequency: Int) {
            self.frequency = frequency
        }
    }
}
