//
//  AppTips.swift
//  DeadLineTodo
//
//  TipKit tips for onboarding
//

import TipKit

// MARK: - Add Content Tip

struct AddContentTip: Tip {
    static let presentEvent = Event(id: "present")
    
    var title: Text { Text("添加一个新任务") }
    var message: Text? { Text("点击加号添加一个新任务") }
    
    var rules: [Rule] {
        #Rule(Self.presentEvent) { $0.donations.count >= 1 }
    }
}

// MARK: - Set Start Time Tip

struct SetStartTimeTip: Tip {
    static let setContentEvent = Event(id: "setContent")
    
    var title: Text { Text("计划任务的开始日期") }
    var message: Text? { Text("选择开始执行任务的日期和时间") }
    
    var rules: [Rule] {
        #Rule(Self.setContentEvent) { $0.donations.count >= 1 }
    }
}

// MARK: - Set Deadline Tip

struct SetDeadlineTip: Tip {
    static let setStartTimeEvent = Event(id: "setStartTime")
    
    var title: Text { Text("计划任务的截止日期") }
    var message: Text? { Text("选择任务的截止日期和时间") }
    
    var rules: [Rule] {
        #Rule(Self.setStartTimeEvent) { $0.donations.count >= 1 }
    }
}

// MARK: - Set Duration Tip

struct SetDurationTip: Tip {
    static let setDeadlineEvent = Event(id: "setDeadline")
    
    var title: Text { Text("计划任务的所需时间") }
    var message: Text? { Text("选择任务预估或计划所需时间") }
    
    var rules: [Rule] {
        #Rule(Self.setDeadlineEvent) { $0.donations.count >= 1 }
    }
}

// MARK: - First Task Tip

struct FirstTaskTip: Tip {
    static let addFirstTaskEvent = Event(id: "addFirstTask")
    
    var title: Text { Text("恭喜你添加了第一个任务！") }
    var message: Text? {
        Text("提示：每个任务最左侧代表当前的时间，左右侧代表截止日期，粉色进度条的宽度代表任务所需时间，蓝色竖线是任务计划开始的时间。所以，粉色进度条会不断向右侧移动，蓝色竖线会不断向左移动。")
    }
    
    var rules: [Rule] {
        #Rule(Self.addFirstTaskEvent) { $0.donations.count == 1 }
    }
}

// MARK: - Emergency View Tip

struct EmergencyViewTip: Tip {
    static let emergencyViewEvent = Event(id: "emergencyView")
    
    var title: Text { Text("这里是紧急待办页面") }
    var message: Text? { Text("计划中已开始的任务将会显示在这里，尽快完成哦！") }
    
    var rules: [Rule] {
        #Rule(Self.emergencyViewEvent) { $0.donations.count == 1 }
    }
}

// MARK: - Score Tip

struct ScoreTip: Tip {
    static let scoreEvent = Event(id: "score")
    
    var title: Text { Text("周效率分数") }
    var message: Text? { Text("越快完成任务，效率分数越高") }
    
    var rules: [Rule] {
        #Rule(Self.scoreEvent) { $0.donations.count == 1 }
    }
}
