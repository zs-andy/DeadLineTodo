//
//  StatisticsView.swift
//  DeadLineTodo
//
//  Created by Andy on 2024/1/28.
//

import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query var tododata: [TodoData]
    @Query var userSetting: [UserSetting]
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var store: StoreKitManager
    @State var heatData: [Double] = []
//    @State var lineWeekDataArray: [lineWeekData] = []
/*    @State*/ var samplelineWeekData: [lineWeekData] = [
    .init(day: "1", value: 44),
    .init(day: "2", value: 70),
    .init(day: "3", value: 66),
    .init(day: "4", value: 77),
    .init(day: "5", value: 49),
    .init(day: "6", value: 89),
    .init(day: "7", value: 92)
]
    @State var isWeekPoint:Bool = true
    @State var isMonthPoint:Bool = false
    @State var isYearPoint:Bool = false
    
    @State var storeView: Bool = false
    
    @State var isWeekTimeTaken: Bool = true
    @State var isMonthTimeTaken: Bool = false
    @State var isYearTimeTaken: Bool = false
    
    @State var isWeekTimeDifference: Bool = true
    @State var isMonthTimeDifference: Bool = false
    @State var isYearTimeDifference: Bool = false
    
    @State var isLoading: Bool = false
//    @State var lineSessonData: [lineSessonData] = []
//    @State var lineYearData: [lineYearData] = []
    
    //异步加载
    @State var WeekDoneNum: Int = 0
    @State var HeatChartData: [Double] = []
    @State var WeekLineChartData: [lineWeekData] = []
    @State var MonthLineChartData: [lineMonthData] = []
    @State var YearLineChartData: [lineYearData] = []
    @State var WorkingWeekTime: [workingTimeWeekData] = []
    @State var WorkingMonthTime: [workingTimeMonthData] = []
    @State var WorkingYearTime: [workingTimeYearData] = []
    @State var WeekTimeDifference: [timeDiferenceWeekData] = []
    @State var MonthTimeDifference: [timeDiferenceMonthData] = []
    @State var YearTimeDifference: [timeDiferenceYearData] = []
    
    
    func loadData(columns: Int) {
        isLoading = true
        
        // **确保在主线程读取 `tododata`，避免跨线程访问**
        let localData = Array(tododata) // 或者深拷贝 tododata
        
        DispatchQueue.global().async {
            let doneNum = getWeekDoneNum(tododata: localData)
            let heatChart = getHeatChartData(tododata: localData, columns: columns)
            let weekLine = getWeekLineChartData(tododata: localData)
            let monthLine = getMonthLineChartData(tododata: localData)
            let yearLine = getYearLineChartData(tododata: localData)
            let workingWeekTime = getWorkingWeekTime(tododata: localData)
            let workingMonthTime = getWorkingMonthTime(tododata: localData)
            let workingYearTime = getWorkingYearTime(tododata: localData)
            let weekTimeDifference = getTimeDifferenceWeek(tododata: localData)
            let monthTimeDifference = getTimeDifferenceMonth(tododata: localData)
            let yearTimeDifference = getTimeDifferenceYear(tododata: localData)
            
            DispatchQueue.main.async {
                WeekDoneNum = doneNum
                HeatChartData = heatChart
                WeekLineChartData = weekLine
                MonthLineChartData = monthLine
                YearLineChartData = yearLine
                WorkingWeekTime = workingWeekTime
                WorkingMonthTime = workingMonthTime
                WorkingYearTime = workingYearTime
                WeekTimeDifference = weekTimeDifference
                MonthTimeDifference = monthTimeDifference
                YearTimeDifference = yearTimeDifference
                self.isLoading = false
            }
        }
    }

    
    var sampleHeatData: [Double] = [0.3, 0.4, 0.4, 0.4, 0.1, 0.5, 0.0,
                                0.1, 0.0, 0.2, 0.2, 0.2, 0.0, 0.2,
                                0.2, 0.5, 0.4, 0.2, 0.4, 0.5, 0.2,
                                0.2, 0.4, 0.3, 0.3, 0.2, 0.4, 0.0,
                                0.0, 0.5, 0.4, 0.3, 0.5, 0.3, 0.0,
                                0.0, 0.5, 0.3, 0.3, 0.0, 0.3, 0.0,
                                0.5, 0.3, 0.3, 0.4, 0.5, 0.5, 0.3,
                                0.4, 0.1, 0.4, 0.2, 0.5, 0.1, 0.4,
                                0.2, 0.5, 0.4, 0.3, 0.5, 0.0, 0.4,
                                0.3, 0.2, 0.1, 0.5, 0.2, 0.0, 0.2,
                                0.5, 0.5, 0.3, 0.4, 0.0, 0.3, 0.3,
                                0.1, 0.2, 0.5, 0.2, 0.1, 0.4, 0.4,
                                0.1, 0.5, 0.3, 0.3, 0.5, 0.4, 0.2,
                                0.4, 0.6, 0.4, 0.2, 0.5, 0.1, 0.4,
                                0.1, 0.7, 0.3, 0.9, 0.5, 0.2, 0.2,
                                0.3, 0.4, 0.4, 0.4, 0.1, 0.5, 0.0,
                                0.1, 0.0, 0.2, 0.2, 0.2, 0.0, 0.2,
                                0.2, 0.5, 0.4, 0.2, 0.4, 0.5, 0.2,
                                0.2, 0.4, 0.3, 0.3, 0.2, 0.4, 0.0,
                                0.0, 0.5, 0.4, 0.3, 0.5, 0.3, 0.0,
                                0.0, 0.5, 0.3, 0.3, 0.0, 0.3, 0.0,
                                0.5, 0.3, 0.3, 0.4, 0.5, 0.5, 0.3,
                                0.4, 0.1, 0.4, 0.2, 0.5, 0.1, 0.4,
                                0.2, 0.5, 0.4, 0.3, 0.5, 0.0, 0.4,
                                0.3, 0.2, 0.1, 0.5, 0.2, 0.0, 0.2,
                                0.5, 0.5, 0.3, 0.4, 0.0, 0.3, 0.3,
                                0.1, 0.2, 0.5, 0.2, 0.1, 0.4, 0.4,
                                0.1, 0.5, 0.3, 0.3, 0.5, 0.4, 0.2,
                                0.4, 0.6, 0.4, 0.2, 0.5, 0.1, 0.4,
                                0.1, 0.7, 0.3, 0.9, 0.5, 0.2, 0.2,
                                0.4, 0.6, 0.4, 0.2, 0.5, 0.1, 0.4,
                                0.1, 0.7, 0.3, 0.9, 0.5, 0.2, 0.2,
                                0.3, 0.4, 0.4, 0.4, 0.1, 0.5, 0.0,
                                0.1, 0.0, 0.2, 0.2, 0.2, 0.0, 0.2,
                                0.2, 0.5, 0.4, 0.2, 0.4, 0.5, 0.2,
                                0.2, 0.4, 0.3, 0.3, 0.2, 0.4, 0.0,
                                0.0, 0.5, 0.4, 0.3, 0.5, 0.3, 0.0,
                                0.0, 0.5, 0.3, 0.3, 0.0, 0.3, 0.0,
                                0.5, 0.3, 0.3, 0.4, 0.5, 0.5, 0.3,
                                0.4, 0.1, 0.4, 0.2, 0.5, 0.1, 0.4,
                                0.5, 0.5, 0.3, 0.4, 0.0, 0.3, 0.3,
                                0.1, 0.2, 0.5, 0.2, 0.1, 0.4, 0.4,
                                0.1, 0.5, 0.3, 0.3, 0.5, 0.4, 0.2,
                                0.4, 0.6, 0.4, 0.2, 0.5, 0.1, 0.4,
                                0.1, 0.7, 0.3, 0.9, 0.5, 0.2, 0.2,
                                0.4, 0.6, 0.4, 0.2, 0.5, 0.1, 0.4,
                                0.1, 0.7, 0.3, 0.9, 0.5, 0.2, 0.2,
                                0.3, 0.4, 0.4, 0.4, 0.1, 0.5, 0.0,
                                0.1, 0.0, 0.2, 0.2, 0.2, 0.0, 0.2,
                                0.2, 0.5, 0.4, 0.2, 0.4, 0.5, 0.2,
                                0.4, 0.1, 0.4, 0.2, 0.5, 0.1, 0.4,
                                0.2, 0.5, 0.4, 0.3, 0.5, 0.0, 0.4,
                                0.3, 0.2, 0.1, 0.5, 0.2, 0.0, 0.2,
                                0.5, 0.5, 0.3, 0.4, 0.0, 0.3, 0.3,
                                0.1, 0.2, 0.5, 0.2, 0.1, 0.4, 0.4,
                                0.1, 0.5, 0.3, 0.3, 0.5, 0.4, 0.2,
                                0.4, 0.6, 0.4, 0.2, 0.5, 0.1, 0.4,
                                0.1, 0.7, 0.3, 0.9, 0.5, 0.2, 0.2,
                                0.4, 0.6, 0.4, 0.2, 0.5, 0.1, 0.4,
                                0.1, 0.5, 0.3, 0.3, 0.5, 0.4, 0.2,
                                0.4, 0.6, 0.4, 0.2, 0.5, 0.1, 0.4,
                                0.1, 0.7, 0.3, 0.9, 0.5, 0.2, 0.2,
                                0.4, 0.6, 0.4, 0.2, 0.5, 0.1, 0.4,
                                0.1, 0.7, 0.3, 0.9, 0.5, 0.2, 0.2,
                                0.3, 0.4, 0.4, 0.4, 0.1, 0.5, 0.0,
                                0.1, 0.0, 0.2, 0.2, 0.2, 0.0, 0.2,
                                0.2, 0.5, 0.4, 0.2, 0.4, 0.5, 0.2,
                                0.4, 0.1, 0.4, 0.2, 0.5, 0.1, 0.4,
                                0.2, 0.5, 0.4, 0.3, 0.5, 0.0, 0.4,
                                0.3, 0.2, 0.1, 0.5, 0.2, 0.0, 0.2,
                                0.5, 0.5, 0.3, 0.4, 0.0, 0.3, 0.3,
                                0.1, 0.2, 0.5, 0.2, 0.1, 0.4, 0.4,]
    let rows = 7
    let columns = 14
    
    func getCulumns(width: CGFloat) -> Int {
        let column:CGFloat = width / 21
        return Int(column) - 3
    }
    
    func getHeatChartData(tododata: [TodoData], columns: Int) -> [Double] {//获取热力图(效率分数)信息
        var sum: Double = 0
        var doneSum: Double = 0
        var _data:[Double] = []
        let allTime: TimeInterval = TimeInterval(columns*7*24*60*60)
        let startTime = (tomorrowStart()?.timeIntervalSince1970 ?? Date().timeIntervalSince1970) - allTime
        for index in 0..<columns*7 {
            sum = 0
            doneSum = 0
            for todo in tododata{
                let dayTimeEnd = (index + 1)*24*60*60
                let dayTimeStart = index*24*60*60
                if todo.doneDate.timeIntervalSince1970 < startTime + Double(dayTimeEnd) && todo.doneDate.timeIntervalSince1970 > startTime + Double(dayTimeStart){
                    if todo.done {
                        doneSum += Double(todo.score)
                        sum += 1
                    }
                }
            }
            _data.append(doneSum/sum/100)
        }
        return _data
    }
    
    func getWeekLineChartData(tododata: [TodoData]) -> [lineWeekData]{ // 获取近一个星期的折线图数据
        var lineWeekDataArray: [lineWeekData] = []
        let calendar = Calendar.current
        // 获取星期数字（1代表星期日，2代表星期一，以此类推）
        var weekdayNumber = 0
        if calendar.component(.weekday, from: Date()) == 1{
            weekdayNumber = 7
        }else{
            weekdayNumber = calendar.component(.weekday, from: Date()) - 1
        }
        var score_: Int = 0
        for index in 0..<7 {
            var num: Int = 0
            var score: Int = 0
            let dayStatTime: TimeInterval = TimeInterval(index*24*60*60)
            let dayEndTime: TimeInterval = TimeInterval((index+1)*24*60*60)
            for todo in tododata{
                if todo.done && todo.doneDate.timeIntervalSince1970 > (tomorrowStart()?.timeIntervalSince1970 ?? Date().timeIntervalSince1970) - TimeInterval(weekdayNumber*24*60*60) + dayStatTime && todo.doneDate.timeIntervalSince1970 < (tomorrowStart()?.timeIntervalSince1970 ?? Date().timeIntervalSince1970) - TimeInterval(weekdayNumber*24*60*60) + dayEndTime{//近一周的每天的
                    num += 1
                    score = todo.score + score
                }
            }
            if num != 0 {
                score_ = score/num
                lineWeekDataArray.append(lineWeekData(day: "\(index+1)", value: score_))
            }else{
                lineWeekDataArray.append(lineWeekData(day: "\(index+1)", value: score_))
            }
        }
        return lineWeekDataArray
    }
    
    func getMonthLineChartData(tododata: [TodoData]) -> [lineMonthData] {
        var lineMonthDataArray: [lineMonthData] = []
        
        let calendar = Calendar.current
        // 获取天
        let dayNumber = calendar.component(.day, from: Date())
        
        var score_: Int = 0
        for index in 0..<getMouthRange(){
            var num: Int = 0
            var score: Int = 0
            let dayStatTime: TimeInterval = TimeInterval(index*24*60*60)
            let dayEndTime: TimeInterval = TimeInterval((index+1)*24*60*60)
            for todo in tododata{
                if todo.done && todo.doneDate.timeIntervalSince1970 > (tomorrowStart()?.timeIntervalSince1970 ?? Date().timeIntervalSince1970) - TimeInterval(dayNumber*24*60*60) + dayStatTime && todo.doneDate.timeIntervalSince1970 < (tomorrowStart()?.timeIntervalSince1970 ?? Date().timeIntervalSince1970) - TimeInterval(dayNumber*24*60*60) + dayEndTime{//近一周的每天的
                    num += 1
                    score = todo.score + score
                }
            }
            if num != 0 {
                score_ = score/num
                lineMonthDataArray.append(lineMonthData(day: "\(index+1)th", value: score_))
            }else{
                lineMonthDataArray.append(lineMonthData(day: "\(index+1)th", value: score_))
            }
        }
        
        return lineMonthDataArray
    }
    
    func tomorrowStart() -> Date? {
        let calendar = Calendar.current
        let currentDate = Date()
        var components = DateComponents()
        components.day = 1
        
        guard let tomorrow = calendar.date(byAdding: components, to: currentDate) else {
            return nil
        }
        
        let startOfDayComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        
        return calendar.date(from: startOfDayComponents)
    }

    
    func getYearLineChartData(tododata: [TodoData]) -> [lineYearData]{
        var lineYearDataArray: [lineYearData] = []
        let calendar = Calendar.current
        let yearNumber = calendar.component(.year, from: Date())
        var score_: Int = 0
        for index in 0..<12{
            var num: Int = 0
            var score: Int = 0
            for todo in tododata{
//                if todo.done && todo.doneDate.timeIntervalSince1970 > start.timeIntervalSince1970 + dayStatTime && todo.doneDate.timeIntervalSince1970 < start.timeIntervalSince1970 + dayEndTime{
//                    num += 1
//                    score = todo.score + score
//                }
                if todo.done && todo.doneDate.timeIntervalSince1970 > startOfMonth(year: yearNumber, month: index+1).timeIntervalSince1970 && todo.doneDate.timeIntervalSince1970 < endOfMonth(year: yearNumber, month: index+1).timeIntervalSince1970{
                    num += 1
                    score = todo.score + score
                }
            }
            if num != 0 {
                score_ = score/num
                lineYearDataArray.append(lineYearData(month: "\(index+1)", value: score_))
            }else{
                lineYearDataArray.append(lineYearData(month: "\(index+1)", value: score_))
            }
        }
        return lineYearDataArray
    }
    
    //指定年月的开始日期
    func startOfMonth(year: Int, month: Int) -> Date {
        let calendar = NSCalendar.current
        var startComps = DateComponents()
        startComps.day = 1
        startComps.month = month
        startComps.year = year
        let startDate = calendar.date(from: startComps)!
        return startDate
    }
    
    func startOfYear(year:Int) -> Date{
        let calendar = NSCalendar.current
        var startComps = DateComponents()
        startComps.day = 1
        startComps.month = 1
        startComps.year = year
        let startDate = calendar.date(from: startComps)!
        return startDate
    }
     
    //指定年月的结束日期
    func endOfMonth(year: Int, month: Int) -> Date {
        let calendar = NSCalendar.current
        var components = DateComponents()
        components.month = 1
         
        let endOfYear = calendar.date(byAdding: components,
                                      to: startOfMonth(year: year, month:month))!
        
        var endMonth: Date = Date()
        if let previousDay = calendar.date(byAdding: .day, value: -1, to: endOfYear) {
            endMonth = previousDay
        } else {
            print("日期操作失败")
        }
        
        return endMonth
    }
    
    //获取月天数
    func getMouthRange() -> Int{
        // 创建一个日历对象
        let calendar = Calendar.current
        // 获取当前日期的月份
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        
        let startDate = calendar.component(.day, from: startOfMonth(year: currentYear, month: currentMonth))
        let endDate1 = calendar.component(.day, from: endOfMonth(year: currentYear, month: currentMonth))
        
        return endDate1 - startDate + 1
    }
    
    func getMonthChartWidth(geoWidth: CGFloat) -> CGFloat{
        if geoWidth - 60 > 1000 {
            return geoWidth - 60
        } else {
            return 1000
        }
    }
    
    func getWeekDoneNum(tododata:[TodoData]) -> Int{
        var num: Int = 0
        let currentDate = Date()
        // 创建一个日历对象
        var calendar = Calendar.current
        // 获取本周的起始日期
        calendar.firstWeekday = 2
        if let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start {
            for todo in tododata{
                if todo.done && todo.doneDate.timeIntervalSince1970 > startOfWeek.timeIntervalSince1970 && todo.doneDate.timeIntervalSince1970 < Date().timeIntervalSince1970{
                    num += 1
                }
            }
        } else {
            print("获取本周起始日期失败")
        }
        return num
    }
    
    func getWorkingWeekTime(tododata: [TodoData]) -> [workingTimeWeekData]{
        var workingTimeArray: [workingTimeWeekData] = []
        let calendar = Calendar.current
        // 获取星期数字（1代表星期日，2代表星期一，以此类推）
        var weekdayNumber = 0
        if calendar.component(.weekday, from: Date()) == 1{
            weekdayNumber = 7
        }else{
            weekdayNumber = calendar.component(.weekday, from: Date()) - 1
        }
        var max: Int = 0
        for index in 0..<7 {
            var timeTaken: Int = 0
            let dayStatTime: TimeInterval = TimeInterval(index*24*60*60)
            let dayEndTime: TimeInterval = TimeInterval((index+1)*24*60*60)
            for todo in tododata{
                if todo.done && todo.doneDate.timeIntervalSince1970 > (tomorrowStart()?.timeIntervalSince1970 ?? Date().timeIntervalSince1970) - TimeInterval(weekdayNumber*24*60*60) + dayStatTime && todo.doneDate.timeIntervalSince1970 < (tomorrowStart()?.timeIntervalSince1970 ?? Date().timeIntervalSince1970) - TimeInterval(weekdayNumber*24*60*60) + dayEndTime{//近一周的每天的
                    timeTaken = Int(todo.actualFinishTime) + timeTaken
                }
            }
            if timeTaken > max {
                max = timeTaken
            }
            workingTimeArray.append(workingTimeWeekData(day: "\(index+1)", value: Double(timeTaken), range: "S"))
        }
        if max < 60 {
            return workingTimeArray
        }else if max >= 60 && max < 60*60{
            for index in 0..<7 {
                workingTimeArray[index].value = workingTimeArray[index].value / 60
                workingTimeArray[index].range = "M"
            }
            return workingTimeArray
        }else if max >= 60*60{
            for index in 0..<7 {
                workingTimeArray[index].value = workingTimeArray[index].value / (60*60)
                workingTimeArray[index].range = "H"
            }
            return workingTimeArray
        }else{
            return workingTimeArray
        }
    }
    
    func getWorkingMonthTime(tododata: [TodoData]) -> [workingTimeMonthData]{
        var workingTimeArray: [workingTimeMonthData] = []
        let calendar = Calendar.current
        // 获取天
        let dayNumber = calendar.component(.day, from: Date())
        var max: Int = 0
        for index in 0..<getMouthRange(){
            var timeTaken: Int = 0
            let dayStatTime: TimeInterval = TimeInterval(index*24*60*60)
            let dayEndTime: TimeInterval = TimeInterval((index+1)*24*60*60)
            for todo in tododata{
                if todo.done && todo.doneDate.timeIntervalSince1970 > (tomorrowStart()?.timeIntervalSince1970 ?? Date().timeIntervalSince1970) - TimeInterval(dayNumber*24*60*60) + dayStatTime && todo.doneDate.timeIntervalSince1970 < (tomorrowStart()?.timeIntervalSince1970 ?? Date().timeIntervalSince1970) - TimeInterval(dayNumber*24*60*60) + dayEndTime{//近一周的每天的
                    timeTaken = Int(todo.actualFinishTime) + timeTaken
                }
            }
            if timeTaken > max {
                max = timeTaken
            }
            workingTimeArray.append(workingTimeMonthData(day: "\(index+1)th", value: Double(timeTaken), range: "S"))

        }
        if max < 60 {
            return workingTimeArray
        }else if max >= 60 && max < 60*60{
            for index in 0..<getMouthRange() {
                workingTimeArray[index].value = workingTimeArray[index].value / 60
                workingTimeArray[index].range = "M"
            }
            return workingTimeArray
        }else if max >= 60*60{
            for index in 0..<getMouthRange() {
                workingTimeArray[index].value = workingTimeArray[index].value / (60*60)
                workingTimeArray[index].range = "H"
            }
            return workingTimeArray
        }else{
            return workingTimeArray
        }
    }
    
    func getWorkingYearTime(tododata: [TodoData]) -> [workingTimeYearData]{
        var workingTimeArray: [workingTimeYearData] = []
        let calendar = Calendar.current
        let yearNumber = calendar.component(.year, from: Date())
        var max: Int = 0
        for index in 0..<12{
            var timeTaken: Int = 0
            for todo in tododata{
                if todo.done && todo.doneDate.timeIntervalSince1970 > startOfMonth(year: yearNumber, month: index+1).timeIntervalSince1970 && todo.doneDate.timeIntervalSince1970 < endOfMonth(year: yearNumber, month: index+1).timeIntervalSince1970{
                    timeTaken = Int(todo.actualFinishTime) + timeTaken
                }
            }
            workingTimeArray.append(workingTimeYearData(month: "\(index+1)", value: Double(timeTaken), range: "S"))
            if timeTaken > max {
                max = timeTaken
            }
        }
        if max < 60 {
            return workingTimeArray
        }else if max >= 60 && max < 60*60{
            for index in 0..<12 {
                workingTimeArray[index].value = workingTimeArray[index].value / 60
                workingTimeArray[index].range = "M"
            }
            return workingTimeArray
        }else if max >= 60*60{
            for index in 0..<12 {
                workingTimeArray[index].value = workingTimeArray[index].value / (60*60)
                workingTimeArray[index].range = "H"
            }
            return workingTimeArray
        }else{
            return workingTimeArray
        }
    }
    
    func getTimeDifferenceYear(tododata: [TodoData]) -> [timeDiferenceYearData]{
        var workingTimeArray: [timeDiferenceYearData] = []
        let calendar = Calendar.current
        let yearNumber = calendar.component(.year, from: Date())
        var max: Int = 0
        for index in 0..<12{
            var timeDiference: Int = 0
            for todo in tododata{
                if todo.done && todo.doneDate.timeIntervalSince1970 > startOfMonth(year: yearNumber, month: index+1).timeIntervalSince1970 && todo.doneDate.timeIntervalSince1970 < endOfMonth(year: yearNumber, month: index+1).timeIntervalSince1970{
                    if todo.actualFinishTime != 0{
                        timeDiference = Int(todo.needTime) - Int(todo.actualFinishTime) + timeDiference
                    }
                }
            }
            workingTimeArray.append(timeDiferenceYearData(month: "\(index+1)", value: Double(timeDiference), range: "S"))
            if abs(timeDiference) > max {
                max = abs(timeDiference)
            }
        }
        if max < 60 {
            return workingTimeArray
        }else if max >= 60 && max < 60*60{
            for index in 0..<12 {
                workingTimeArray[index].value = workingTimeArray[index].value / 60
                workingTimeArray[index].range = "M"
            }
            return workingTimeArray
        }else if max >= 60*60{
            for index in 0..<12 {
                workingTimeArray[index].value = workingTimeArray[index].value / (60*60)
                workingTimeArray[index].range = "H"
            }
            return workingTimeArray
        }else{
            return workingTimeArray
        }
    }
    
    func getTimeDifferenceMonth(tododata: [TodoData]) -> [timeDiferenceMonthData]{
        var workingTimeArray: [timeDiferenceMonthData] = []
        let calendar = Calendar.current
        let dayNumber = calendar.component(.day, from: Date())
        var max: Int = 0
        for index in 0..<getMouthRange(){
            var timeDiference: Int = 0
            let dayStatTime: TimeInterval = TimeInterval(index*24*60*60)
            let dayEndTime: TimeInterval = TimeInterval((index+1)*24*60*60)
            for todo in tododata{
                if todo.done && todo.doneDate.timeIntervalSince1970 > (tomorrowStart()?.timeIntervalSince1970 ?? Date().timeIntervalSince1970) - TimeInterval(dayNumber*24*60*60) + dayStatTime && todo.doneDate.timeIntervalSince1970 < (tomorrowStart()?.timeIntervalSince1970 ?? Date().timeIntervalSince1970) - TimeInterval(dayNumber*24*60*60) + dayEndTime{//近一周的每天的
                    if todo.actualFinishTime != 0{
                        timeDiference = Int(todo.needTime) - Int(todo.actualFinishTime) + timeDiference
                    }
                }
            }
            if abs(timeDiference) > max {
                max = abs(timeDiference)
            }
            workingTimeArray.append(timeDiferenceMonthData(day: "\(index+1)th", value: Double(timeDiference), range: "S"))

        }
        if max < 60 {
            return workingTimeArray
        }else if max >= 60 && max < 60*60{
            for index in 0..<getMouthRange() {
                workingTimeArray[index].value = workingTimeArray[index].value / 60
                workingTimeArray[index].range = "M"
            }
            return workingTimeArray
        }else if max >= 60*60{
            for index in 0..<getMouthRange() {
                workingTimeArray[index].value = workingTimeArray[index].value / (60*60)
                workingTimeArray[index].range = "H"
            }
            return workingTimeArray
        }else{
            return workingTimeArray
        }
    }
    
    func getTimeDifferenceWeek(tododata: [TodoData]) -> [timeDiferenceWeekData]{
        var workingTimeArray: [timeDiferenceWeekData] = []
        let calendar = Calendar.current
        // 获取星期数字（1代表星期日，2代表星期一，以此类推）
        var weekdayNumber = 0
        if calendar.component(.weekday, from: Date()) == 1{
            weekdayNumber = 7
        }else{
            weekdayNumber = calendar.component(.weekday, from: Date()) - 1
        }
        var max: Int = 0
        for index in 0..<7 {
            var timeDiference: Int = 0
            let dayStatTime: TimeInterval = TimeInterval(index*24*60*60)
            let dayEndTime: TimeInterval = TimeInterval((index+1)*24*60*60)
            for todo in tododata{
                if todo.done && todo.doneDate.timeIntervalSince1970 > (tomorrowStart()?.timeIntervalSince1970 ?? Date().timeIntervalSince1970) - TimeInterval(weekdayNumber*24*60*60) + dayStatTime && todo.doneDate.timeIntervalSince1970 < (tomorrowStart()?.timeIntervalSince1970 ?? Date().timeIntervalSince1970) - TimeInterval(weekdayNumber*24*60*60) + dayEndTime{//近一周的每天的
                    if todo.actualFinishTime != 0{
                        timeDiference = Int(todo.needTime) - Int(todo.actualFinishTime) + timeDiference
                    }
                }
            }
            if abs(timeDiference) > max {
                max = abs(timeDiference)
            }
            workingTimeArray.append(timeDiferenceWeekData(day: "\(index+1)", value: Double(timeDiference), range: "S"))
        }
        if max < 60 {
            return workingTimeArray
        }else if max >= 60 && max < 60*60{
            for index in 0..<7 {
                workingTimeArray[index].value = workingTimeArray[index].value / 60
                workingTimeArray[index].range = "M"
            }
            return workingTimeArray
        }else if max >= 60*60{
            for index in 0..<7 {
                workingTimeArray[index].value = workingTimeArray[index].value / (60*60)
                workingTimeArray[index].range = "H"
            }
            return workingTimeArray
        }else{
            return workingTimeArray
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack{
                HStack{
                    Text("统计")
                        .font(.system(size: 30))
                        .bold()
                        .padding(20)
                        .foregroundStyle(Color.myBlack)
                    Spacer()
                }
//                ScrollView(.horizontal, showsIndicators: false){
//                    VStack{
//                        HStack{
//                            ForEach(1..<32) { hour in
//                               // 时间轴上的每天标签
//                               Text("\(hour)日")
//                                   .font(.caption)
//                                   .foregroundColor(Color.myBlack)
//
//                               // 可以在这里添加Deadline的显示逻辑，根据需要自定义样式
//                           }
//                        }
//                    }
//                }
//                .clipShape(RoundedRectangle(cornerRadius: 20.0, style: .continuous))
//                .padding()
//                .frame(maxWidth: .infinity)
                ScrollView{
                    VStack{
                        HStack{
                            Text("这一周已完成\(WeekDoneNum)项任务")
                                .font(.system(size: 20))
                                .padding(.horizontal, 40)
                                .bold()
                                .foregroundStyle(Color.blackBlue1)
                            Spacer()
                        }
                        .padding(.bottom)
                        HStack{
                            Image(systemName: "calendar")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.blackGray)
                            Text("效率分数热力图")
                                .font(.system(size: 13))
                                .bold()
                                .foregroundStyle(Color.blackGray)
                            Spacer()
                        }
                        .padding(.horizontal, 40)
                        if HeatChartData.count == getCulumns(width: geo.size.width) * 7{
                            //正式发布使用片段
                            if store.hasPurchased{
                                
                                ContributionChartView(data: HeatChartData,
                                                      rows: rows,
                                                      columns: getCulumns(width: geo.size.width),
                                                      targetValue: 1,
                                                      blockColor: .green2)
                            }else{
                                //演示使用片段
                                ContributionChartView(data: sampleHeatData,
                                                      rows: rows,
                                                      columns: getCulumns(width: geo.size.width),
                                                      targetValue: 0.5,
                                                      blockColor: .green2)
                            }
                        }
                        HStack{
                            if isWeekPoint{
                                Image(systemName: "chart.xyaxis.line")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.blackGray)
                                Text("周效率分数")
                                    .font(.system(size: 13))
                                    .bold()
                                    .foregroundStyle(Color.blackGray)
                            }else if isMonthPoint{
                                Image(systemName: "chart.xyaxis.line")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.blackGray)
                                Text("月效率分数")
                                    .font(.system(size: 13))
                                    .bold()
                                    .foregroundStyle(Color.blackGray)
                            }else{
                                Image(systemName: "chart.xyaxis.line")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.blackGray)
                                Text("年效率分数")
                                    .font(.system(size: 13))
                                    .bold()
                                    .foregroundStyle(Color.blackGray)
                            }
                            Spacer()
                            ZStack{
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(Color.creamBlue)
                                    .frame(width: 110)
                                HStack{
                                    Button(action:{
                                        withAnimation(.default){
                                            isWeekPoint = true
                                            isMonthPoint = false
                                            isYearPoint = false
                                        }
                                    }){
                                        ZStack{
                                            if isWeekPoint{
                                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                    .fill(Color.blackBlue2)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(2)
                                            }
                                            Text("周")
                                                .font(.system(size: 10))
                                                .bold()
                                                .foregroundStyle(isWeekPoint ? Color.white : Color.blackBlue2)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    Button(action:{
                                        withAnimation(.default){
                                            if store.hasPurchased{
                                                isWeekPoint = false
                                                isMonthPoint = true
                                                isYearPoint = false
                                            }
                                        }
                                    }){
                                        ZStack{
                                            if isMonthPoint{
                                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                    .fill(Color.blackBlue2)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(2)
                                            }
                                            Text("月")
                                                .font(.system(size: 10))
                                                .bold()
                                                .foregroundStyle(isMonthPoint ? Color.white : Color.blackBlue2)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    Button(action:{
                                        withAnimation(.default){
                                            if store.hasPurchased{
                                                isWeekPoint = false
                                                isMonthPoint = false
                                                isYearPoint = true
                                            }
                                        }
                                    }){
                                        ZStack{
                                            if isYearPoint{
                                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                    .fill(Color.blackBlue2)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(2)
                                            }
                                            Text("年")
                                                .font(.system(size: 10))
                                                .bold()
                                                .foregroundStyle(isYearPoint ? Color.white : Color.blackBlue2)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                .frame(width: 110, height: 25)
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 15)
                        //正式发布使用片段
                        if isWeekPoint{
                            if store.hasPurchased{
                                ScrollView(.horizontal, showsIndicators: false){
                                    ZStack{
                                        Chart{
                                            ForEach(WeekLineChartData/*samplelineWeekData*/, id: \.day) { lineData in
                                                LineMark(x: .value("day", lineData.day),
                                                         y: .value("total", lineData.value))
                                                .interpolationMethod(.catmullRom)
                                                .foregroundStyle(Color.creamBlue)
                                            }
                                        }
                                        .frame(width: geo.size.width - 60, height: 150)
                                    }
                                    .padding(.vertical, 5)
                                    .frame(maxWidth: .infinity)
                                }
                                .padding(.horizontal, 30)
                            }else{
                                ScrollView(.horizontal, showsIndicators: false){
                                    ZStack{
                                        Chart{
                                            ForEach(samplelineWeekData, id: \.day) { lineData in
                                                LineMark(x: .value("day", lineData.day),
                                                         y: .value("total", lineData.value))
                                                .interpolationMethod(.catmullRom)
                                                .foregroundStyle(Color.creamBlue)
                                            }
                                        }
                                        .frame(width: geo.size.width - 60, height: 150)
                                    }
                                    .padding(.vertical, 5)
                                    .frame(maxWidth: .infinity)
                                }
                                .padding(.horizontal, 30)
                            }
                        }else if isMonthPoint{
                            ScrollView(.horizontal, showsIndicators: false){
                                ZStack{
                                    Chart{
                                        ForEach(MonthLineChartData, id: \.day) { lineData in
                                            LineMark(x: .value("day", lineData.day),
                                                     y: .value("total", lineData.value))
                                            .interpolationMethod(.catmullRom)
                                            .foregroundStyle(Color.creamBlue)
                                        }
                                    }
                                    .frame(width: getMonthChartWidth(geoWidth: geo.size.width), height: 150)
                                }
                                .padding(.vertical, 5)
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal, 30)
                        }else{
                            ScrollView(.horizontal, showsIndicators: false){
                                ZStack{
                                    Chart{
                                        ForEach(YearLineChartData, id: \.month) { lineData in
                                            LineMark(x: .value("day", lineData.month),
                                                     y: .value("total", lineData.value))
                                            .interpolationMethod(.catmullRom)
                                            .foregroundStyle(Color.creamBlue)
                                        }
                                    }
                                    .frame(width: geo.size.width, height: 150)
                                }
                                .padding(.vertical, 5)
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal, 30)
                        }
                        //////////////////////////////
                        HStack{
                            if isWeekTimeTaken{
                                Image(systemName: "clock.badge.checkmark")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.blackGray)
                                Text("周累计完成时间")
                                    .font(.system(size: 13))
                                    .bold()
                                    .foregroundStyle(Color.blackGray)
                            }else if isMonthTimeTaken{
                                Image(systemName: "clock.badge.checkmark")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.blackGray)
                                Text("月累计完成时间")
                                    .font(.system(size: 13))
                                    .bold()
                                    .foregroundStyle(Color.blackGray)
                            }else{
                                Image(systemName: "clock.badge.checkmark")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.blackGray)
                                Text("年累计完成时间")
                                    .font(.system(size: 13))
                                    .bold()
                                    .foregroundStyle(Color.blackGray)
                            }
                            Spacer()
                            ZStack{
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(Color.creamBlue)
                                    .frame(width: 110)
                                HStack{
                                    Button(action:{
                                        withAnimation(.default){
                                            isWeekTimeTaken = true
                                            isMonthTimeTaken = false
                                            isYearTimeTaken = false
                                        }
                                    }){
                                        ZStack{
                                            if isWeekTimeTaken{
                                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                    .fill(Color.blackBlue2)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(2)
                                            }
                                            Text("周")
                                                .font(.system(size: 10))
                                                .bold()
                                                .foregroundStyle(isWeekTimeTaken ? Color.white : Color.blackBlue2)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    Button(action:{
                                        withAnimation(.default){
                                            if store.hasPurchased{
                                                isWeekTimeTaken = false
                                                isMonthTimeTaken = true
                                                isYearTimeTaken = false
                                            }
                                        }
                                    }){
                                        ZStack{
                                            if isMonthTimeTaken{
                                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                    .fill(Color.blackBlue2)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(2)
                                            }
                                            Text("月")
                                                .font(.system(size: 10))
                                                .bold()
                                                .foregroundStyle(isMonthTimeTaken ? Color.white : Color.blackBlue2)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    Button(action:{
                                        withAnimation(.default){
                                            if store.hasPurchased{
                                                isWeekTimeTaken = false
                                                isMonthTimeTaken = false
                                                isYearTimeTaken = true
                                            }
                                        }
                                    }){
                                        ZStack{
                                            if isYearTimeTaken{
                                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                    .fill(Color.blackBlue2)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(2)
                                            }
                                            Text("年")
                                                .font(.system(size: 10))
                                                .bold()
                                                .foregroundStyle(isYearTimeTaken ? Color.white : Color.blackBlue2)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                .frame(width: 110, height: 25)
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 15)
                        if isWeekTimeTaken{
                            ScrollView(.horizontal, showsIndicators: false){
                                HStack{
                                    if store.hasPurchased{
                                        ZStack{
                                            Chart{
                                                ForEach(WorkingWeekTime/*samplelineWeekData*/, id: \.day) { lineData in
                                                    BarMark(x: .value("day", lineData.day),
                                                            y: .value("total", lineData.value))
                                                    .foregroundStyle(Color.creamBlue)
                                                }
                                            }
                                            .frame(width: geo.size.width - 60, height: 150)
                                        }
                                        .padding(.vertical, 5)
                                        .frame(maxWidth: .infinity)
                                    }else{
                                        ZStack{
                                            Chart{
                                                ForEach(samplelineWeekData, id: \.day) { lineData in
                                                    BarMark(x: .value("day", lineData.day),
                                                            y: .value("total", lineData.value))
                                                    .foregroundStyle(Color.creamBlue)
                                                }
                                            }
                                            .frame(width: geo.size.width - 60, height: 150)
                                        }
                                        .padding(.vertical, 5)
                                        .frame(maxWidth: .infinity)
                                    }
                                    if getWorkingWeekTime(tododata: tododata)[0].range == "S"{
                                        Text("秒")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.gray)
                                            .rotationEffect(Angle(degrees: 90))
                                            .offset(x: -5)
                                    }else if getWorkingWeekTime(tododata: tododata)[0].range == "M"{
                                        Text("分钟")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.gray)
                                            .rotationEffect(Angle(degrees: 90))
                                            .offset(x: -5)
                                    }else if getWorkingWeekTime(tododata: tododata)[0].range == "H"{
                                        Text("小时")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.gray)
                                            .rotationEffect(Angle(degrees: 90))
                                            .offset(x: -5)
                                    }
                                }
                            }
                            .padding(.horizontal, 30)
                        }else if isMonthTimeTaken{
                            ScrollView(.horizontal, showsIndicators: false){
                                HStack{
                                    ZStack{
                                        Chart{
                                            ForEach(WorkingMonthTime, id: \.day) { lineData in
                                                BarMark(x: .value("day", lineData.day),
                                                         y: .value("total", lineData.value))
                                                .foregroundStyle(Color.creamBlue)
                                            }
                                        }
                                        .frame(width: getMonthChartWidth(geoWidth: geo.size.width), height: 150)
                                    }
                                    .padding(.vertical, 5)
                                    .frame(maxWidth: .infinity)
                                    if getWorkingMonthTime(tododata: tododata)[0].range == "S"{
                                        Text("秒")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.gray)
                                            .rotationEffect(Angle(degrees: 90))
                                            .offset(x: -5)
                                    }else if getWorkingMonthTime(tododata: tododata)[0].range == "M"{
                                        Text("分钟")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.gray)
                                            .rotationEffect(Angle(degrees: 90))
                                            .offset(x: -5)
                                    }else if getWorkingMonthTime(tododata: tododata)[0].range == "H"{
                                        Text("小时")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.gray)
                                            .rotationEffect(Angle(degrees: 90))
                                            .offset(x: -5)
                                    }
                                }
                            }
                            .padding(.horizontal, 30)
                        }else{
                            ScrollView(.horizontal, showsIndicators: false){
                                HStack{
                                    ZStack{
                                        Chart{
                                            ForEach(WorkingYearTime, id: \.month) { lineData in
                                                BarMark(x: .value("day", lineData.month),
                                                         y: .value("total", lineData.value))
                                                .foregroundStyle(Color.creamBlue)
                                            }
                                        }
                                        .frame(width: geo.size.width, height: 150)
                                    }
                                    .padding(.vertical, 5)
                                    .frame(maxWidth: .infinity)
                                    if getWorkingYearTime(tododata: tododata)[0].range == "S"{
                                        Text("秒")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.gray)
                                            .rotationEffect(Angle(degrees: 90))
                                            .offset(x: -5)
                                    }else if getWorkingYearTime(tododata: tododata)[0].range == "M"{
                                        Text("分钟")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.gray)
                                            .rotationEffect(Angle(degrees: 90))
                                            .offset(x: -5)
                                    }else if getWorkingYearTime(tododata: tododata)[0].range == "H"{
                                        Text("小时")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.gray)
                                            .rotationEffect(Angle(degrees: 90))
                                            .offset(x: -5)
                                    }
                                }
                            }
                            .padding(.horizontal, 30)
                        }
                        //////////
                        HStack{
                            if isWeekTimeDifference{
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.blackGray)
                                Text("周完成时间差")
                                    .font(.system(size: 13))
                                    .bold()
                                    .foregroundStyle(Color.blackGray)
                            }else if isMonthTimeDifference{
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.blackGray)
                                Text("月完成时间差")
                                    .font(.system(size: 13))
                                    .bold()
                                    .foregroundStyle(Color.blackGray)
                            }else{
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.blackGray)
                                Text("年完成时间差")
                                    .font(.system(size: 13))
                                    .bold()
                                    .foregroundStyle(Color.blackGray)
                            }
                            Spacer()
                            ZStack{
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(Color.creamBlue)
                                    .frame(width: 110)
                                HStack{
                                    Button(action:{
                                        withAnimation(.default){
                                            isWeekTimeDifference = true
                                            isMonthTimeDifference = false
                                            isYearTimeTaken = false
                                        }
                                    }){
                                        ZStack{
                                            if isWeekTimeDifference{
                                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                    .fill(Color.blackBlue2)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(2)
                                            }
                                            Text("周")
                                                .font(.system(size: 10))
                                                .bold()
                                                .foregroundStyle(isWeekTimeDifference ? Color.white : Color.blackBlue2)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    Button(action:{
                                        withAnimation(.default){
                                            if store.hasPurchased{
                                                isWeekTimeDifference = false
                                                isMonthTimeDifference = true
                                                isYearTimeDifference = false
                                            }
                                        }
                                    }){
                                        ZStack{
                                            if isMonthTimeDifference{
                                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                    .fill(Color.blackBlue2)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(2)
                                            }
                                            Text("月")
                                                .font(.system(size: 10))
                                                .bold()
                                                .foregroundStyle(isMonthTimeDifference ? Color.white : Color.blackBlue2)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    Button(action:{
                                        withAnimation(.default){
                                            if store.hasPurchased{
                                                isWeekTimeDifference = false
                                                isMonthTimeDifference = false
                                                isYearTimeDifference = true
                                            }
                                        }
                                    }){
                                        ZStack{
                                            if isYearTimeDifference{
                                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                    .fill(Color.blackBlue2)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(2)
                                            }
                                            Text("年")
                                                .font(.system(size: 10))
                                                .bold()
                                                .foregroundStyle(isYearTimeDifference ? Color.white : Color.blackBlue2)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                .frame(width: 110, height: 25)
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 15)
                        if isWeekTimeDifference{
                            ScrollView(.horizontal, showsIndicators: false){
                                HStack{
                                    if store.hasPurchased{
                                        ZStack{
                                            Chart{
                                                ForEach(WeekTimeDifference/*samplelineWeekData*/, id: \.day) { lineData in
                                                    BarMark(x: .value("day", lineData.day),
                                                            y: .value("total", lineData.value))
                                                    .foregroundStyle(Color.creamBlue)
                                                }
                                            }
                                            .frame(width: geo.size.width - 60, height: 150)
                                        }
                                        .padding(.vertical, 5)
                                        .frame(maxWidth: .infinity)
                                    }else{
                                        ZStack{
                                            Chart{
                                                ForEach(samplelineWeekData, id: \.day) { lineData in
                                                    BarMark(x: .value("day", lineData.day),
                                                            y: .value("total", lineData.value))
                                                    .foregroundStyle(Color.creamBlue)
                                                }
                                            }
                                            .frame(width: geo.size.width - 60, height: 150)
                                        }
                                        .padding(.vertical, 5)
                                        .frame(maxWidth: .infinity)
                                    }
                                    if getTimeDifferenceWeek(tododata: tododata)[0].range == "S"{
                                        Text("秒")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.gray)
                                            .rotationEffect(Angle(degrees: 90))
                                            .offset(x: -5)
                                    }else if getTimeDifferenceWeek(tododata: tododata)[0].range == "M"{
                                        Text("分钟")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.gray)
                                            .rotationEffect(Angle(degrees: 90))
                                            .offset(x: -5)
                                    }else if getTimeDifferenceWeek(tododata: tododata)[0].range == "H"{
                                        Text("小时")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.gray)
                                            .rotationEffect(Angle(degrees: 90))
                                            .offset(x: -5)
                                    }
                                }
                            }
                            .padding(.horizontal, 30)
                        }else if isMonthTimeDifference{
                            ScrollView(.horizontal, showsIndicators: false){
                                HStack{
                                    ZStack{
                                        Chart{
                                            ForEach(MonthTimeDifference, id: \.day) { lineData in
                                                BarMark(x: .value("day", lineData.day),
                                                         y: .value("total", lineData.value))
                                                .foregroundStyle(Color.creamBlue)
                                            }
                                        }
                                        .frame(width: getMonthChartWidth(geoWidth: geo.size.width), height: 150)
                                    }
                                    .padding(.vertical, 5)
                                    .frame(maxWidth: .infinity)
                                    if getTimeDifferenceMonth(tododata: tododata)[0].range == "S"{
                                        Text("秒")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.gray)
                                            .rotationEffect(Angle(degrees: 90))
                                            .offset(x: -5)
                                    }else if getTimeDifferenceMonth(tododata: tododata)[0].range == "M"{
                                        Text("分钟")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.gray)
                                            .rotationEffect(Angle(degrees: 90))
                                            .offset(x: -5)
                                    }else if getTimeDifferenceMonth(tododata: tododata)[0].range == "H"{
                                        Text("小时")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.gray)
                                            .rotationEffect(Angle(degrees: 90))
                                            .offset(x: -5)
                                    }
                                }
                            }
                            .padding(.horizontal, 30)
                        }else{
                            ScrollView(.horizontal, showsIndicators: false){
                                HStack{
                                    ZStack{
                                        Chart{
                                            ForEach(YearTimeDifference, id: \.month) { lineData in
                                                BarMark(x: .value("day", lineData.month),
                                                         y: .value("total", lineData.value))
                                                .foregroundStyle(Color.creamBlue)
                                            }
                                        }
                                        .frame(width: geo.size.width, height: 150)
                                    }
                                    .padding(.vertical, 5)
                                    .frame(maxWidth: .infinity)
                                    if getTimeDifferenceYear(tododata: tododata)[0].range == "S"{
                                        Text("秒")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.gray)
                                            .rotationEffect(Angle(degrees: 90))
                                            .offset(x: -5)
                                    }else if getTimeDifferenceYear(tododata: tododata)[0].range == "M"{
                                        Text("分钟")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.gray)
                                            .rotationEffect(Angle(degrees: 90))
                                            .offset(x: -5)
                                    }else if getTimeDifferenceYear(tododata: tododata)[0].range == "H"{
                                        Text("小时")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.gray)
                                            .rotationEffect(Angle(degrees: 90))
                                            .offset(x: -5)
                                    }
                                }
                            }
                            .padding(.horizontal, 30)
                        }
                        if store.hasPurchased == false{
                            HStack{
                                Text("以上为样例数据")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.blackGray)
                                Button(action:{
                                    storeView = true
                                }){
                                    Text("购买高级功能")
                                        .bold()
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color.blackBlue2)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        }
                    }
                    .padding(.bottom, 150)
                }
            }
            .fullScreenCover(isPresented: $storeView, content: {// 模态跳转
                StoreView(isStorePresent: $storeView)
            })
            .onAppear {
                let columns = getCulumns(width: geo.size.width)
                for _ in 0..<columns*7 {
                    heatData.append(0.4)
                }
                loadData(columns: columns)
            }
            .onChange(of: geo.size.width) { oldWidth, newWidth in
                let newcolumns = getCulumns(width: newWidth)
                heatData = []
                for _ in 0..<newcolumns*7  {
                    heatData.append(0.4)
                }
                loadData(columns: newcolumns)
            }

        }
    }
}
