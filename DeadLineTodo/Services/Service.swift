//
//  Service.swift
//  DeadLineTodo
//
//  Created by Haiyao Zhou on 10/04/2025.
//

import Foundation
import SwiftData

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
    
    func calculateRepeatTimeByEndDate (repeatTodo: inout TodoData, repeatTime: Int, modelContext: ModelContext) {
        repeatTodo.endDate = Date(timeIntervalSince1970: repeatTodo.endDate.timeIntervalSince1970 + periodTimes[repeatTime - 1])
        repeatTodo.emergencyDate = Date(timeIntervalSince1970: repeatTodo.emergencyDate.timeIntervalSince1970 + periodTimes[repeatTime - 1])
        repeatTodo.addDate = helper.getStartOfDay(startDate: repeatTodo.emergencyDate)
        while repeatTodo.endDate < Date() {//改为endDate判断
            repeatTodo.endDate = Date(timeIntervalSince1970: repeatTodo.endDate.timeIntervalSince1970 + periodTimes[repeatTime - 1])
            repeatTodo.emergencyDate = Date(timeIntervalSince1970: repeatTodo.emergencyDate.timeIntervalSince1970 + periodTimes[repeatTime - 1])
            repeatTodo.addDate = helper.getStartOfDay(startDate: repeatTodo.emergencyDate)
        }
        modelContext.insert(repeatTodo)
    }
}
