//
//  VersionSchemaV2.swift
//  DeadLineTodo
//
//  Created by Andy on 2024/2/15.
//

import Foundation
import SwiftData

enum TodoDataSchemaV1: @preconcurrency VersionedSchema {
    static var models: [any PersistentModel.Type]{
        [TodoData.self, UserSetting.self]
    }
    @MainActor static var versionIdentifier: Schema.Version = .init(1, 3, 0)
}

extension TodoDataSchemaV1 {
    @Model
    class TodoData: Identifiable{
        var id = UUID()
        
        var content: String
        var tips: String
        
        var endDate: Date
        var addDate: Date
        var doneDate: Date
        
        var leftTime: TimeInterval
        
        var Day: Int
        var Hour: Int
        var Min: Int
        var Sec: Int
        
        var actualFinishTime: TimeInterval
        
        var todo: Bool
        var done: Bool
        var emergency: Bool
        
        var offset: CGFloat
        
        var score: Int
        
        init(content: String, tips: String, endDate: Date, addDate: Date, doneDate: Date, leftTime: TimeInterval, Day: Int, Hour: Int, Min: Int, Sec: Int, actualFinishTime: TimeInterval, todo: Bool, done: Bool, emergency: Bool, offset: CGFloat, score: Int) {
            self.content = content
            self.tips = tips
            self.endDate = endDate
            self.addDate = addDate
            self.doneDate = doneDate
            self.leftTime = leftTime
            self.Day = Day
            self.Hour = Hour
            self.Min = Min
            self.Sec = Sec
            self.actualFinishTime = actualFinishTime
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
