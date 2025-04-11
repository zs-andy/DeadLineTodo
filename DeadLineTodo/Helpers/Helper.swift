//
//  Helper.swift
//  DeadLineTodo
//
//  Created by Haiyao Zhou on 10/04/2025.
//

import Foundation
import SwiftUI

//Rename Helper.swift to something more meaningful
class Helper {
    func getStartOfDay(startDate: Date) -> Date{
        let currentDate = startDate
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let startOfDay = calendar.startOfDay(for: currentDate)
        
        return Date(timeIntervalSince1970: startOfDay.timeIntervalSince1970)
    }
    
    func getStartOfWeek(startDate: Date) -> Date{
        let currentDate = startDate
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        calendar.firstWeekday = 2
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
        return Date(timeIntervalSince1970: startOfWeek.timeIntervalSince1970)
    }
    
    func getStartOfMonth(startDate: Date) -> Date{
        let currentDate = startDate
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        return startOfMonth
    }
    //redecide redundancy with notificationhelper
    func getNeedTime(day: Double, hour: Double, min: Double) -> Double {
        return day*60*60*24 + hour*60*60 + min*60
    }
    
    func calendarIdIterate(calendarId: inout Int, calendar2Id: inout Int) {
        calendarId += 1
        calendar2Id += 1
    }
    
    func getLeftTime(todo: TodoData) -> TimeInterval {
        let time = todo.Day*60*60*24 + todo.Hour*60*60 + todo.Min*60
        let leftTime = todo.endDate.timeIntervalSince1970 - Date().timeIntervalSince1970 - Double(time)
        return leftTime
    }
    
    func getScoreFromArray(tododata: [TodoData]) -> Int {//计算效率分数
        var score: Int = 0
        var num: Int = 0
        let currentDate = Date()
        // 创建一个日历对象
        var calendar = Calendar.current
        // 获取本周的起始日期
        calendar.firstWeekday = 2
        if let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start {
            for todo in tododata{
                if todo.done && todo.doneDate.timeIntervalSince1970 > startOfWeek.timeIntervalSince1970 {
                    num += 1
                    score = todo.score + score
                }
            }
        } else {
            print("获取本周起始日期失败")
        }
//        for todo in tododata{
//            if todo.done && todo.doneDate.timeIntervalSince1970 > Date().timeIntervalSince1970 - TimeInterval(7*24*60*60){//近一周的
//                num += 1
//                score = todo.score + score
//            }
//        }
        if num != 0{
            return score/num
        }else{
            return 0
        }
    }
    
    func getScore(todo: TodoData) -> Int {//计算效率分数
        var score1: Double = 0
        var score2: Double = 0
        let needTime = todo.Day*60*60*24 + todo.Hour*60*60 + todo.Min*60 + todo.Sec
        let sum = todo.endDate.timeIntervalSince1970 - todo.addDate.timeIntervalSince1970
        score1 = (todo.endDate.timeIntervalSince1970 - todo.doneDate.timeIntervalSince1970 - Double(needTime)) / sum
        if score1 >= 1{
            score1 = 1
        }
        if score1 <= 0{
            score1 = 0
        }
        if todo.needTime >= todo.actualFinishTime {
            score2 = 100
        }else{
            if (todo.actualFinishTime - todo.needTime) / todo.needTime >= 1{
                score2 = 0
            }else{
                score2 = 100 - ((todo.actualFinishTime - todo.needTime) / todo.needTime) * 100
            }
        }
        return Int(score1 * 100 * 0.3) + Int(score2 * 0.7)
    }
    
    func refreshTime(tododata: inout [TodoData], index: Int, EmergencyNum: inout Int, EditTodoIsPresent: Bool, AddTodoIsPresent: Bool) {
        if tododata.indices.contains(index) {
            if EditTodoIsPresent == false && AddTodoIsPresent == false && tododata[index].done == false{
                if tododata[index].doing{
                    tododata[index].actualFinishTime = tododata[index].lastTime + Date().timeIntervalSince1970 - tododata[index].startDoingDate.timeIntervalSince1970
                }
                tododata[index].leftTime = getLeftTime(todo: tododata[index])
                if tododata[index].leftTime <= 60 {
                    if tododata[index].emergency == false{
                        withAnimation(.default){
                            EmergencyNum += 1
                        }
                    }
                    tododata[index].emergency = true
                }else{
                    if tododata[index].emergency == true{
                        withAnimation(.default){
                            EmergencyNum -= 1
                        }
                    }
                    tododata[index].emergency = false
                }
            }
        }
    }
}
