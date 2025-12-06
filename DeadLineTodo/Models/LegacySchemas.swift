//
//  LegacySchemas.swift
//  DeadLineTodo
//
//  Legacy schema versions for migration support
//

import Foundation
import SwiftData

// MARK: - Schema V1

enum TodoDataSchemaV1: @preconcurrency VersionedSchema {
    static var models: [any PersistentModel.Type] { [TodoData.self] }
    @MainActor static var versionIdentifier: Schema.Version = .init(1, 0, 0)
    
    @Model class TodoData: Identifiable {
        var id = UUID()
        var content: String = ""
        var priority: Int = 0
        var endDate: Date = Date()
        var addDate: Date = Date()
        var doneDate: Date = Date()
        var emergencyDate: Date = Date()
        var leftTime: TimeInterval = 0
        var needTime: TimeInterval = 0
        var Day: Int = 0
        var Hour: Int = 2
        var Min: Int = 0
        var Sec: Int = 0
        var todo: Bool = false
        var done: Bool = false
        var emergency: Bool = false
        var offset: CGFloat = 0
        
        init(content: String, priority: Int, endDate: Date, addDate: Date, doneDate: Date, emergencyDate: Date, leftTime: TimeInterval, needTime: TimeInterval, Day: Int, Hour: Int, Min: Int, Sec: Int, todo: Bool, done: Bool, emergency: Bool, offset: CGFloat) {
            self.content = content; self.priority = priority; self.endDate = endDate; self.addDate = addDate
            self.doneDate = doneDate; self.emergencyDate = emergencyDate; self.leftTime = leftTime
            self.needTime = needTime; self.Day = Day; self.Hour = Hour; self.Min = Min; self.Sec = Sec
            self.todo = todo; self.done = done; self.emergency = emergency; self.offset = offset
        }
    }
}

// MARK: - Schema V2

enum TodoDataSchemaV2: @preconcurrency VersionedSchema {
    static var models: [any PersistentModel.Type] { [TodoData.self] }
    @MainActor static var versionIdentifier: Schema.Version = .init(1, 1, 0)
    
    @Model class TodoData: Identifiable {
        var id = UUID()
        var content: String = ""
        var priority: Int = 0
        var endDate: Date = Date()
        var addDate: Date = Date()
        var doneDate: Date = Date()
        var emergencyDate: Date = Date()
        var startDoingDate: Date = Date()
        var leftTime: TimeInterval = 0
        var needTime: TimeInterval = 0
        var actualFinishTime: TimeInterval = 0
        var Day: Int = 0
        var Hour: Int = 2
        var Min: Int = 0
        var Sec: Int = 0
        var todo: Bool = false
        var done: Bool = false
        var emergency: Bool = false
        var doing: Bool = false
        var offset: CGFloat = 0
        
        init(content: String, priority: Int, endDate: Date, addDate: Date, doneDate: Date, emergencyDate: Date, startDoingDate: Date, leftTime: TimeInterval, needTime: TimeInterval, actualFinishTime: TimeInterval, Day: Int, Hour: Int, Min: Int, Sec: Int, todo: Bool, done: Bool, emergency: Bool, doing: Bool, offset: CGFloat) {
            self.content = content; self.priority = priority; self.endDate = endDate; self.addDate = addDate
            self.doneDate = doneDate; self.emergencyDate = emergencyDate; self.startDoingDate = startDoingDate
            self.leftTime = leftTime; self.needTime = needTime; self.actualFinishTime = actualFinishTime
            self.Day = Day; self.Hour = Hour; self.Min = Min; self.Sec = Sec
            self.todo = todo; self.done = done; self.emergency = emergency; self.doing = doing; self.offset = offset
        }
    }
}

// MARK: - Schema V3

enum TodoDataSchemaV3: @preconcurrency VersionedSchema {
    static var models: [any PersistentModel.Type] { [TodoData.self] }
    @MainActor static var versionIdentifier: Schema.Version = .init(2, 0, 0)
    
    @Model class TodoData: Identifiable {
        var id = UUID()
        var content: String = ""
        var priority: Int = 0
        var endDate: Date = Date()
        var addDate: Date = Date()
        var doneDate: Date = Date()
        var emergencyDate: Date = Date()
        var startDoingDate: Date = Date()
        var leftTime: TimeInterval = 0
        var needTime: TimeInterval = 0
        var actualFinishTime: TimeInterval = 0
        var lastTime: TimeInterval = 0
        var Day: Int = 0
        var Hour: Int = 2
        var Min: Int = 0
        var Sec: Int = 0
        var todo: Bool = false
        var done: Bool = false
        var emergency: Bool = false
        var doing: Bool = false
        var offset: CGFloat = 0
        var score: Int = 100
        
        init(content: String, priority: Int, endDate: Date, addDate: Date, doneDate: Date, emergencyDate: Date, startDoingDate: Date, leftTime: TimeInterval, needTime: TimeInterval, actualFinishTime: TimeInterval, lastTime: TimeInterval, Day: Int, Hour: Int, Min: Int, Sec: Int, todo: Bool, done: Bool, emergency: Bool, doing: Bool, offset: CGFloat, score: Int) {
            self.content = content; self.priority = priority; self.endDate = endDate; self.addDate = addDate
            self.doneDate = doneDate; self.emergencyDate = emergencyDate; self.startDoingDate = startDoingDate
            self.leftTime = leftTime; self.needTime = needTime; self.actualFinishTime = actualFinishTime
            self.lastTime = lastTime; self.Day = Day; self.Hour = Hour; self.Min = Min; self.Sec = Sec
            self.todo = todo; self.done = done; self.emergency = emergency; self.doing = doing
            self.offset = offset; self.score = score
        }
    }
}

// MARK: - Schema V4

enum TodoDataSchemaV4: @preconcurrency VersionedSchema {
    static var models: [any PersistentModel.Type] { [TodoData.self, UserSetting.self] }
    @MainActor static var versionIdentifier: Schema.Version = .init(2, 1, 0)
    
    @Model class TodoData: Identifiable {
        var id = UUID()
        var content: String = ""
        var priority: Int = 0
        var endDate: Date = Date()
        var addDate: Date = Date()
        var doneDate: Date = Date()
        var emergencyDate: Date = Date()
        var startDoingDate: Date = Date()
        var leftTime: TimeInterval = 0
        var needTime: TimeInterval = 0
        var actualFinishTime: TimeInterval = 0
        var lastTime: TimeInterval = 0
        var Day: Int = 0
        var Hour: Int = 2
        var Min: Int = 0
        var Sec: Int = 0
        var todo: Bool = false
        var done: Bool = false
        var emergency: Bool = false
        var doing: Bool = false
        var offset: CGFloat = 0
        var score: Int = 100
        
        init(content: String, priority: Int, endDate: Date, addDate: Date, doneDate: Date, emergencyDate: Date, startDoingDate: Date, leftTime: TimeInterval, needTime: TimeInterval, actualFinishTime: TimeInterval, lastTime: TimeInterval, Day: Int, Hour: Int, Min: Int, Sec: Int, todo: Bool, done: Bool, emergency: Bool, doing: Bool, offset: CGFloat, score: Int) {
            self.content = content; self.priority = priority; self.endDate = endDate; self.addDate = addDate
            self.doneDate = doneDate; self.emergencyDate = emergencyDate; self.startDoingDate = startDoingDate
            self.leftTime = leftTime; self.needTime = needTime; self.actualFinishTime = actualFinishTime
            self.lastTime = lastTime; self.Day = Day; self.Hour = Hour; self.Min = Min; self.Sec = Sec
            self.todo = todo; self.done = done; self.emergency = emergency; self.doing = doing
            self.offset = offset; self.score = score
        }
    }
    
    @Model class UserSetting: Identifiable {
        var frequency: Int = 1
        var reminder: Bool = true
        init(frequency: Int, reminder: Bool) { self.frequency = frequency; self.reminder = reminder }
    }
}

// MARK: - Schema V5

enum TodoDataSchemaV5: @preconcurrency VersionedSchema {
    static var models: [any PersistentModel.Type] { [TodoData.self, UserSetting.self] }
    @MainActor static var versionIdentifier: Schema.Version = .init(2, 2, 0)
    
    @Model class TodoData: Identifiable {
        var id = UUID()
        var content: String = ""
        var repeatTime: Int = 0
        var priority: Int = 0
        var endDate: Date = Date()
        var addDate: Date = Date()
        var doneDate: Date = Date()
        var emergencyDate: Date = Date()
        var startDoingDate: Date = Date()
        var leftTime: TimeInterval = 0
        var needTime: TimeInterval = 0
        var actualFinishTime: TimeInterval = 0
        var lastTime: TimeInterval = 0
        var initialNeedTime: TimeInterval = 0
        var Day: Int = 0
        var Hour: Int = 2
        var Min: Int = 0
        var Sec: Int = 0
        var todo: Bool = false
        var done: Bool = false
        var emergency: Bool = false
        var doing: Bool = false
        var offset: CGFloat = 0
        var score: Int = 100
        var times: Int = 0
        
        init(content: String, repeatTime: Int, priority: Int, endDate: Date, addDate: Date, doneDate: Date, emergencyDate: Date, startDoingDate: Date, leftTime: TimeInterval, needTime: TimeInterval, actualFinishTime: TimeInterval, lastTime: TimeInterval, initialNeedTime: TimeInterval, Day: Int, Hour: Int, Min: Int, Sec: Int, todo: Bool, done: Bool, emergency: Bool, doing: Bool, offset: CGFloat, score: Int, times: Int) {
            self.content = content; self.repeatTime = repeatTime; self.priority = priority
            self.endDate = endDate; self.addDate = addDate; self.doneDate = doneDate
            self.emergencyDate = emergencyDate; self.startDoingDate = startDoingDate
            self.leftTime = leftTime; self.needTime = needTime; self.actualFinishTime = actualFinishTime
            self.lastTime = lastTime; self.initialNeedTime = initialNeedTime
            self.Day = Day; self.Hour = Hour; self.Min = Min; self.Sec = Sec
            self.todo = todo; self.done = done; self.emergency = emergency; self.doing = doing
            self.offset = offset; self.score = score; self.times = times
        }
    }
    
    @Model class UserSetting: Identifiable {
        var frequency: Int = 1
        var reminder: Bool = true
        var hasPurchased: Bool = false
        init(frequency: Int, reminder: Bool, hasPurchased: Bool) {
            self.frequency = frequency; self.reminder = reminder; self.hasPurchased = hasPurchased
        }
    }
}

// MARK: - Schema V6

enum TodoDataSchemaV6: @preconcurrency VersionedSchema {
    static var models: [any PersistentModel.Type] { [TodoData.self, UserSetting.self] }
    @MainActor static var versionIdentifier: Schema.Version = .init(2, 3, 0)
    
    @Model class TodoData: Identifiable {
        var id = UUID()
        var content: String = ""
        var repeatTime: Int = 0
        var priority: Int = 0
        var endDate: Date = Date()
        var addDate: Date = Date()
        var doneDate: Date = Date()
        var emergencyDate: Date = Date()
        var startDoingDate: Date = Date()
        var leftTime: TimeInterval = 0
        var needTime: TimeInterval = 0
        var actualFinishTime: TimeInterval = 0
        var lastTime: TimeInterval = 0
        var initialNeedTime: TimeInterval = 0
        var Day: Int = 0
        var Hour: Int = 2
        var Min: Int = 0
        var Sec: Int = 0
        var todo: Bool = false
        var done: Bool = false
        var emergency: Bool = false
        var doing: Bool = false
        var offset: CGFloat = 0
        var score: Int = 100
        var times: Int = 0
        
        init(content: String, repeatTime: Int, priority: Int, endDate: Date, addDate: Date, doneDate: Date, emergencyDate: Date, startDoingDate: Date, leftTime: TimeInterval, needTime: TimeInterval, actualFinishTime: TimeInterval, lastTime: TimeInterval, initialNeedTime: TimeInterval, Day: Int, Hour: Int, Min: Int, Sec: Int, todo: Bool, done: Bool, emergency: Bool, doing: Bool, offset: CGFloat, score: Int, times: Int) {
            self.content = content; self.repeatTime = repeatTime; self.priority = priority
            self.endDate = endDate; self.addDate = addDate; self.doneDate = doneDate
            self.emergencyDate = emergencyDate; self.startDoingDate = startDoingDate
            self.leftTime = leftTime; self.needTime = needTime; self.actualFinishTime = actualFinishTime
            self.lastTime = lastTime; self.initialNeedTime = initialNeedTime
            self.Day = Day; self.Hour = Hour; self.Min = Min; self.Sec = Sec
            self.todo = todo; self.done = done; self.emergency = emergency; self.doing = doing
            self.offset = offset; self.score = score; self.times = times
        }
    }
    
    @Model class UserSetting: Identifiable {
        var frequency: Int = 1
        var reminder: Bool = true
        var hasPurchased: Bool = false
        var calendar: Bool = false
        init(frequency: Int, reminder: Bool, hasPurchased: Bool, calendar: Bool) {
            self.frequency = frequency; self.reminder = reminder
            self.hasPurchased = hasPurchased; self.calendar = calendar
        }
    }
}

// MARK: - Schema V7

enum TodoDataSchemaV7: @preconcurrency VersionedSchema {
    static var models: [any PersistentModel.Type] { [TodoData.self, UserSetting.self] }
    @MainActor static var versionIdentifier: Schema.Version = .init(2, 4, 0)
    
    @Model class TodoData: Identifiable {
        var id = UUID()
        var content: String = ""
        var repeatTime: Int = 0
        var priority: Int = 0
        var endDate: Date = Date()
        var addDate: Date = Date()
        var doneDate: Date = Date()
        var emergencyDate: Date = Date()
        var startDoingDate: Date = Date()
        var leftTime: TimeInterval = 0
        var needTime: TimeInterval = 0
        var actualFinishTime: TimeInterval = 0
        var lastTime: TimeInterval = 0
        var initialNeedTime: TimeInterval = 0
        var Day: Int = 0
        var Hour: Int = 2
        var Min: Int = 0
        var Sec: Int = 0
        var todo: Bool = false
        var done: Bool = false
        var emergency: Bool = false
        var doing: Bool = false
        var offset: CGFloat = 0
        var score: Int = 100
        var times: Int = 0
        
        init(content: String, repeatTime: Int, priority: Int, endDate: Date, addDate: Date, doneDate: Date, emergencyDate: Date, startDoingDate: Date, leftTime: TimeInterval, needTime: TimeInterval, actualFinishTime: TimeInterval, lastTime: TimeInterval, initialNeedTime: TimeInterval, Day: Int, Hour: Int, Min: Int, Sec: Int, todo: Bool, done: Bool, emergency: Bool, doing: Bool, offset: CGFloat, score: Int, times: Int) {
            self.content = content; self.repeatTime = repeatTime; self.priority = priority
            self.endDate = endDate; self.addDate = addDate; self.doneDate = doneDate
            self.emergencyDate = emergencyDate; self.startDoingDate = startDoingDate
            self.leftTime = leftTime; self.needTime = needTime; self.actualFinishTime = actualFinishTime
            self.lastTime = lastTime; self.initialNeedTime = initialNeedTime
            self.Day = Day; self.Hour = Hour; self.Min = Min; self.Sec = Sec
            self.todo = todo; self.done = done; self.emergency = emergency; self.doing = doing
            self.offset = offset; self.score = score; self.times = times
        }
    }
    
    @Model class UserSetting: Identifiable {
        var frequency: Int = 1
        var reminder: Bool = true
        var hasPurchased: Bool = false
        var calendar: Bool = false
        init(frequency: Int, reminder: Bool, hasPurchased: Bool, calendar: Bool) {
            self.frequency = frequency; self.reminder = reminder
            self.hasPurchased = hasPurchased; self.calendar = calendar
        }
    }
}

// MARK: - Schema V8

enum TodoDataSchemaV8: @preconcurrency VersionedSchema {
    static var models: [any PersistentModel.Type] { [TodoData.self, UserSetting.self] }
    @MainActor static var versionIdentifier: Schema.Version = .init(2, 4, 1)
    
    @Model class TodoData: Identifiable {
        var id = UUID()
        var content: String = ""
        var repeatTime: Int = 0
        var priority: Int = 0
        var endDate: Date = Date()
        var addDate: Date = Date()
        var doneDate: Date = Date()
        var emergencyDate: Date = Date()
        var startDoingDate: Date = Date()
        var leftTime: TimeInterval = 0
        var needTime: TimeInterval = 0
        var actualFinishTime: TimeInterval = 0
        var lastTime: TimeInterval = 0
        var initialNeedTime: TimeInterval = 0
        var Day: Int = 0
        var Hour: Int = 2
        var Min: Int = 0
        var Sec: Int = 0
        var todo: Bool = false
        var done: Bool = false
        var emergency: Bool = false
        var doing: Bool = false
        var offset: CGFloat = 0
        var score: Int = 100
        var times: Int = 0
        
        init(content: String, repeatTime: Int, priority: Int, endDate: Date, addDate: Date, doneDate: Date, emergencyDate: Date, startDoingDate: Date, leftTime: TimeInterval, needTime: TimeInterval, actualFinishTime: TimeInterval, lastTime: TimeInterval, initialNeedTime: TimeInterval, Day: Int, Hour: Int, Min: Int, Sec: Int, todo: Bool, done: Bool, emergency: Bool, doing: Bool, offset: CGFloat, score: Int, times: Int) {
            self.content = content; self.repeatTime = repeatTime; self.priority = priority
            self.endDate = endDate; self.addDate = addDate; self.doneDate = doneDate
            self.emergencyDate = emergencyDate; self.startDoingDate = startDoingDate
            self.leftTime = leftTime; self.needTime = needTime; self.actualFinishTime = actualFinishTime
            self.lastTime = lastTime; self.initialNeedTime = initialNeedTime
            self.Day = Day; self.Hour = Hour; self.Min = Min; self.Sec = Sec
            self.todo = todo; self.done = done; self.emergency = emergency; self.doing = doing
            self.offset = offset; self.score = score; self.times = times
        }
    }
    
    @Model class UserSetting: Identifiable {
        var frequency: Int = 1
        var reminder: Bool = true
        var hasPurchased: Bool = false
        var calendar: Bool = false
        var selectedOptions: [String] = []
        init(frequency: Int, reminder: Bool, hasPurchased: Bool, calendar: Bool, selectedOptions: [String]) {
            self.frequency = frequency; self.reminder = reminder
            self.hasPurchased = hasPurchased; self.calendar = calendar
            self.selectedOptions = selectedOptions
        }
    }
}
