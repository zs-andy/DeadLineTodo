//
//  Service.swift
//  DeadLineTodo
//
//  Created by Haiyao Zhou on 10/04/2025.
//

import Foundation

class Service {
    let helper = Helper()
    //periodTimes stores total seconds for day, week, month
    let periodTimes: [Double] = [60*60*24, 60*60*24*7, 60*60*24*30]
    //TODO: Change function name later
    func calculateRepeatDay (edittodo: inout TodoData, repeatTime: Int) {
        edittodo.endDate = Date(timeIntervalSince1970: edittodo.endDate.timeIntervalSince1970 + periodTimes[repeatTime - 1])
        edittodo.emergencyDate = Date(timeIntervalSince1970: edittodo.emergencyDate.timeIntervalSince1970 + periodTimes[repeatTime - 1])
        edittodo.addDate = helper.getStartOfDay(startDate: edittodo.emergencyDate)
        while edittodo.emergencyDate.timeIntervalSince1970 < Date().timeIntervalSince1970 {
            edittodo.endDate = Date(timeIntervalSince1970: edittodo.endDate.timeIntervalSince1970 + periodTimes[repeatTime - 1])
            edittodo.emergencyDate = Date(timeIntervalSince1970: edittodo.emergencyDate.timeIntervalSince1970 + periodTimes[repeatTime - 1])
            edittodo.addDate = helper.getStartOfDay(startDate: edittodo.emergencyDate)
        }
    }
    
    func getLeftTime(todo: TodoData) -> TimeInterval {
        let time = todo.Day*60*60*24 + todo.Hour*60*60 + todo.Min*60
        let leftTime = todo.endDate.timeIntervalSince1970 - Date().timeIntervalSince1970 - Double(time)
        return leftTime
    }
}
