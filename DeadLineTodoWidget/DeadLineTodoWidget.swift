//
//  DeadLineTodoWidget.swift
//  DeadLineTodoWidget
//
//  Created by Andy on 2024/3/21.
//

import WidgetKit
import SwiftUI
import SwiftData
import Charts


struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: hourOffset*10, to: currentDate)!
           let entry = SimpleEntry(date: entryDate)
           entries.append(entry)
        }
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct DeadLineTodoWidgetEntryView : View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) var family: WidgetFamily
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
//        case .systemExtraLarge:
//            ExtraLargeWidgetView(entry: entry)
        default:
            EmptyView()
        }
    }
}

struct SmallWidgetView: View {
    var entry: Provider.Entry
    
    @Query(descriptor) var todaytodo: [TodoData]
    
    func percentage(todaytodo: [TodoData]) -> Double{
        var num: Double = 0
        var sum: Double = 0
        for todo in todaytodo {
            sum += 1
            if todo.done {
                num += 1
            }
        }
        return num/sum
    }
    
    static var descriptor: FetchDescriptor<TodoData>{
        let currentDate = Date()
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let startOfDay = calendar.startOfDay(for: currentDate)
        let endOfDay = Date(timeIntervalSince1970: startOfDay.timeIntervalSince1970 + 60*60*24)
        
        let predicate = #Predicate<TodoData> {$0.emergencyDate >= startOfDay && $0.emergencyDate <= endOfDay}
        let sort = [SortDescriptor(\TodoData.endDate)]
        
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: sort)
        
        return descriptor
    }

    var body: some View {
        HStack{
            ZStack {
                Circle()
                    .stroke(Color.grayWhite2,lineWidth: 10)
                RingShape(progress: percentage(todaytodo: todaytodo), thickness: 10)
                    .fill(Color.creamBlue)
                if percentage(todaytodo: todaytodo) >= 0 && percentage(todaytodo: todaytodo) <= 100{
                    HStack{
                        Text("\(Int(percentage(todaytodo: todaytodo)*100))")
                            .bold()
                            .foregroundStyle(Color.myBlack)
                            .font(.system(size: 25))
                            .offset(x: 4)
                        Text("%")
                            .bold()
                            .foregroundStyle(Color.grayWhite4)
                            .font(.system(size: 15))
                            .offset(x: -4, y: 3)
                    }
                    .padding(.leading, 4)
                }
            }
            .frame(maxHeight: .infinity)
            .frame(width: 90, alignment: .center)
        }
    }
}


struct MediumWidgetView: View {
    var entry: Provider.Entry
    
    @Query(todoDescriptor) var tododata: [TodoData]
    @Query(descriptor) var todaytodo: [TodoData]
    
    func percentage(todaytodo: [TodoData]) -> Double{
        var num: Double = 0
        var sum: Double = 0
        for todo in todaytodo {
            sum += 1
            if todo.done {
                num += 1
            }
        }
        return num/sum
    }
    
    static var todoDescriptor: FetchDescriptor<TodoData>{
        let currentDate = Date()
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let startOfDay = calendar.startOfDay(for: currentDate)
        let endOfDay = Date(timeIntervalSince1970: startOfDay.timeIntervalSince1970 + 60*60*24)
        
        let predicate = #Predicate<TodoData> { ($0.todo == true || $0.emergency == true) && $0.endDate >= startOfDay && ($0.emergencyDate <= endOfDay)}
        let sort = [SortDescriptor(\TodoData.endDate)]
        
        var descriptor = FetchDescriptor(predicate: predicate, sortBy: sort)
        descriptor.fetchLimit = 3
        
        return descriptor
    }
    
    static var descriptor: FetchDescriptor<TodoData>{
        let currentDate = Date()
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let startOfDay = calendar.startOfDay(for: currentDate)
        let endOfDay = Date(timeIntervalSince1970: startOfDay.timeIntervalSince1970 + 60*60*24)
        
        let predicate = #Predicate<TodoData> {$0.emergencyDate >= startOfDay && $0.emergencyDate <= endOfDay}
        let sort = [SortDescriptor(\TodoData.endDate)]
        
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: sort)
        
        return descriptor
    }
    
    func decomposeSeconds(totalSeconds: TimeInterval) -> (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let days = Int(totalSeconds / (24 * 60 * 60))
        let remainingSeconds = totalSeconds - TimeInterval(days * 24 * 60 * 60)
        
        let hours = Int(remainingSeconds / 3600)
        let remainingSecondsAfterHours = remainingSeconds - TimeInterval(hours * 3600)
        
        let minutes = Int(remainingSecondsAfterHours / 60)
        let seconds = Int(remainingSecondsAfterHours.truncatingRemainder(dividingBy: 60))
        
        return (days, hours, minutes, seconds)
    }
    
    func getLeftTime(todo: TodoData) -> TimeInterval {
        let leftTime = todo.endDate.timeIntervalSince1970 - entry.date.timeIntervalSince1970 - todo.needTime + todo.actualFinishTime
        return max(leftTime, 0)
    }
    
    func pastDue(todo: TodoData) -> Bool {
        let current = entry.date
        if todo.endDate - todo.needTime < current{
            return true
        } else {
            return false
        }
    }

    var body: some View {
        HStack{
            VStack {
                ForEach(tododata) { todo in
                    ZStack{
                        if pastDue(todo: todo){
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.creamPink)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .opacity(0.5)
                        }else{
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.grayWhite2)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                        }
                        VStack(alignment: .leading){
                            HStack() {
        //                        RoundedRectangle(cornerRadius: 5, style: .continuous)
        //                            .fill(Color.creamBlue)
        //                            .frame(width: 15, height:15)
                                Text(todo.content)
                                    .padding(.horizontal, 10)
                                    .bold()
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.myBlack)
                                    .lineLimit(1)
                                Spacer()
                            }
                            HStack{
                                Text("剩余时间:")
                                    .foregroundStyle(Color.blackGray)
                                    .bold()
                                    .padding(.trailing, -2)
                                    .padding(.leading, 10)
                                    .font(.system(size: 8))
                                if getLeftTime(todo: todo) > 0{
                                    HStack{
                                        if decomposeSeconds(totalSeconds: getLeftTime(todo: todo)).days != 0{
                                            Text("\(decomposeSeconds(totalSeconds: getLeftTime(todo: todo)).days)天")
                                                .foregroundStyle(Color.blackGray)
                                                .padding(.bottom, 0.5)
                                                .padding(.horizontal, -3)
                                                .bold()
                                                .font(.system(size: 8))
                                        }
                                        if decomposeSeconds(totalSeconds: getLeftTime(todo: todo)).hours != 0 {
                                            Text("\(decomposeSeconds(totalSeconds: getLeftTime(todo: todo)).hours)时")
                                                .foregroundStyle(Color.blackGray)
                                                .padding(.bottom, 0.5)
                                                .padding(.horizontal, -3)
                                                .bold()
                                                .font(.system(size: 8))
                                        }
                                        if decomposeSeconds(totalSeconds: getLeftTime(todo: todo)).minutes != 0{
                                            Text("\(decomposeSeconds(totalSeconds: getLeftTime(todo: todo)).minutes)分")
                                                .foregroundStyle(Color.blackGray)
                                                .padding(.bottom, 0.5)
                                                .padding(.horizontal, -3)
                                                .bold()
                                                .font(.system(size: 8))
                                        }
                                        Spacer()
                                    }
                                }else if (todo.endDate.timeIntervalSince1970 - entry.date.timeIntervalSince1970) <= 0{
                                    HStack{
                                        Text("已截止")
                                            .foregroundStyle(Color.creamBrown)
                                            .padding(.bottom, 0.5)
                                            .padding(.horizontal, -3)
                                            .bold()
                                            .font(.system(size: 8))
                                        Spacer()
                                    }
                                }else{
                                    HStack{
                                        Text("将截止")
                                            .foregroundStyle(Color.creamBrown)
                                            .padding(.bottom, 0.5)
                                            .padding(.horizontal, -3)
                                            .bold()
                                            .font(.system(size: 8))
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.trailing)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .overlay {
                if tododata.isEmpty {
                    Text("今日没有任务")
                        .bold()
                        .foregroundStyle(Color.myBlack)
                }
            }
            ZStack {
                Circle()
                    .stroke(Color.grayWhite2,lineWidth: 10)
                    .padding(.leading, -15)
                    .padding(7)
                RingShape(progress: percentage(todaytodo: todaytodo), thickness: 10)
                    .fill(Color.creamBlue)
                    .padding(.leading, -15)
                    .padding(7)
                if percentage(todaytodo: todaytodo) >= 0 && percentage(todaytodo: todaytodo) <= 100{
                    HStack{
                        Text("\(Int(percentage(todaytodo: todaytodo)*100))")
                            .bold()
                            .foregroundStyle(Color.myBlack)
                            .font(.system(size: 25))
                            .offset(x: 4)
                        Text("%")
                            .bold()
                            .foregroundStyle(Color.grayWhite4)
                            .font(.system(size: 15))
                            .offset(x: -4, y: 3)
                    }
                    .padding(.leading, 4)
                    .padding(.leading, -15)
                    .padding(7)
                }
            }
            .frame(maxHeight: .infinity)
            .frame(width: 90, alignment: .center)
        }
    }
}

struct LargeWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.modelContext) var modelContext
    
    @State var WeekLineChartData: [lineWeekData] = []
    @State var WorkingWeekTime: [workingTimeWeekData] = []
    @State var isLoading: Bool = false
    
    @Query(todoDescriptor) var tododata: [TodoData]
    @Query(descriptor) var todaytodo: [TodoData]
    @Query var alltodo: [TodoData]
    
    func percentage(todaytodo: [TodoData]) -> Double{
        var num: Double = 0
        var sum: Double = 0
        for todo in todaytodo {
            sum += 1
            if todo.done {
                num += 1
            }
        }
        return num/sum
    }
    
    static var todoDescriptor: FetchDescriptor<TodoData>{
        let currentDate = Date()
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        calendar.firstWeekday = 2
        if let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start {
            let endOfWeek = Date(timeIntervalSince1970: startOfWeek.timeIntervalSince1970 + 7*24*60*60)
            let predicate = #Predicate<TodoData> { ($0.todo == true || $0.emergency == true) && ($0.emergencyDate <= endOfWeek)}
            let sort = [SortDescriptor(\TodoData.endDate)]
            
            var descriptor = FetchDescriptor(predicate: predicate, sortBy: sort)
            descriptor.fetchLimit = 3
            return descriptor
        } else {
            print("获取本周起始日期失败")
            let now = Date()
            let predicate = #Predicate<TodoData> { ($0.todo == true || $0.emergency == true) && ($0.emergencyDate <= now)}
            let sort = [SortDescriptor(\TodoData.endDate)]
            
            var descriptor = FetchDescriptor(predicate: predicate, sortBy: sort)
            descriptor.fetchLimit = 3
            
            return descriptor
        }
    }
    
    static var descriptor: FetchDescriptor<TodoData>{
        let currentDate = Date()
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        if let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start {
            let endOfWeek = Date(timeIntervalSince1970: startOfWeek.timeIntervalSince1970 + 7*24*60*60)
            let predicate = #Predicate<TodoData> {$0.endDate >= startOfWeek && $0.emergencyDate <= endOfWeek}
            let sort = [SortDescriptor(\TodoData.endDate)]
            
            var descriptor = FetchDescriptor(predicate: predicate, sortBy: sort)
            descriptor.fetchLimit = 3
            
            return descriptor
        } else {
            print("获取本周起始日期失败")
            let now = Date()
            let predicate = #Predicate<TodoData> {$0.endDate >= now && $0.emergencyDate <= now}
            let sort = [SortDescriptor(\TodoData.endDate)]
            
            var descriptor = FetchDescriptor(predicate: predicate, sortBy: sort)
            descriptor.fetchLimit = 3
            
            return descriptor
        }
    }
    
    
    func getWeekDoneNum(tododata:[TodoData]) -> Int{
        var num: Int = 0
        let currentDate = entry.date
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

    func getScore(tododata: [TodoData]) -> Int {//计算效率分数
        var score: Int = 0
        var num: Int = 0
        let currentDate = entry.date
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
    
    func getWorkingTime(tododata: [TodoData]) -> Int {
        var time: Int = 0
        let currentDate = entry.date
        // 创建一个日历对象
        var calendar = Calendar.current
        // 获取本周的起始日期
        calendar.firstWeekday = 2
        if let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start {
            for todo in tododata{
                if todo.done && todo.doneDate.timeIntervalSince1970 > startOfWeek.timeIntervalSince1970 {
                    time = Int(todo.actualFinishTime) + time
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
        return time
    }
    
    func secondsConvert(seconds: Int) -> (hours: Int, minutes: Int, seconds: Int) {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = (seconds % 3600) % 60
        return (hours, minutes, seconds)
    }
    
    func decomposeSeconds(totalSeconds: TimeInterval) -> (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let days = Int(totalSeconds / (24 * 60 * 60))
        let remainingSeconds = totalSeconds - TimeInterval(days * 24 * 60 * 60)
        
        let hours = Int(remainingSeconds / 3600)
        let remainingSecondsAfterHours = remainingSeconds - TimeInterval(hours * 3600)
        
        let minutes = Int(remainingSecondsAfterHours / 60)
        let seconds = Int(remainingSecondsAfterHours.truncatingRemainder(dividingBy: 60))
        
        return (days, hours, minutes, seconds)
    }
    
    func getLeftTime(todo: TodoData) -> TimeInterval {
        let leftTime = todo.endDate.timeIntervalSince1970 - entry.date.timeIntervalSince1970 - todo.needTime + todo.actualFinishTime
        return max(leftTime, 0)
    }
    
    func pastDue(todo: TodoData) -> Bool {
        let current = entry.date
        if todo.endDate - todo.needTime < current{
            return true
        } else {
            return false
        }
    }
    
    var body: some View {
        VStack{
            HStack{
                VStack(alignment: .leading){
                    Text("已完成")
                        .bold()
                        .font(.system(size: 12))
                        .foregroundStyle(Color.grayWhite4)
                    HStack{
                        Text("\(getWeekDoneNum(tododata: alltodo))")
                            .bold()
                            .foregroundStyle(Color.blackBlue2)
                            .font(.system(size: 20))
                        
                    }
                }
                .padding(.trailing)
                VStack(alignment: .leading){
                    Text("效率")
                        .bold()
                        .font(.system(size: 12))
                        .foregroundStyle(Color.grayWhite4)
                    HStack{
                        Text("\(getScore(tododata: alltodo))")
                            .bold()
                            .foregroundStyle(Color.blackBlue2)
                            .font(.system(size: 20))
                    }
                }
                .padding(.trailing)
                VStack(alignment: .leading){
                    Text("总时长")
                        .bold()
                        .font(.system(size: 12))
                        .foregroundStyle(Color.grayWhite4)
                    HStack{
                        Text("\(secondsConvert(seconds: getWorkingTime(tododata: alltodo)).hours)h\(secondsConvert(seconds: getWorkingTime(tododata: alltodo)).minutes)m")
                            .bold()
                            .foregroundStyle(Color.blackBlue2)
                            .font(.system(size: 20))
                    }
                }
                .padding(.trailing)
                Spacer()
            }
            WidgetLineChartView(entry: entry)
            VStack{
                ForEach(tododata) { todo in
                    ZStack{
                        if pastDue(todo: todo){
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.creamPink)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .opacity(0.5)
                        }else{
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.grayWhite2)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                        }
                        VStack(alignment: .leading){
                            HStack() {
        //                        RoundedRectangle(cornerRadius: 5, style: .continuous)
        //                            .fill(Color.creamBlue)
        //                            .frame(width: 15, height:15)
                                Text(todo.content)
                                    .padding(.horizontal, 10)
                                    .bold()
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.myBlack)
                                    .lineLimit(1)
                                Spacer()
                            }
                            HStack{
                                Text("剩余时间:")
                                    .foregroundStyle(Color.blackGray)
                                    .bold()
                                    .padding(.trailing, -2)
                                    .padding(.leading, 10)
                                    .font(.system(size: 8))
                                if getLeftTime(todo: todo) > 0{
                                    HStack{
                                        if decomposeSeconds(totalSeconds: getLeftTime(todo: todo)).days != 0{
                                            Text("\(decomposeSeconds(totalSeconds: getLeftTime(todo: todo)).days)天")
                                                .foregroundStyle(Color.blackGray)
                                                .padding(.bottom, 0.5)
                                                .padding(.horizontal, -3)
                                                .bold()
                                                .font(.system(size: 8))
                                        }
                                        if decomposeSeconds(totalSeconds: getLeftTime(todo: todo)).hours != 0 {
                                            Text("\(decomposeSeconds(totalSeconds: getLeftTime(todo: todo)).hours)时")
                                                .foregroundStyle(Color.blackGray)
                                                .padding(.bottom, 0.5)
                                                .padding(.horizontal, -3)
                                                .bold()
                                                .font(.system(size: 8))
                                        }
                                        if decomposeSeconds(totalSeconds: getLeftTime(todo: todo)).minutes != 0{
                                            Text("\(decomposeSeconds(totalSeconds: getLeftTime(todo: todo)).minutes)分")
                                                .foregroundStyle(Color.blackGray)
                                                .padding(.bottom, 0.5)
                                                .padding(.horizontal, -3)
                                                .bold()
                                                .font(.system(size: 8))
                                        }
                                        Spacer()
                                    }
                                }else if (todo.endDate.timeIntervalSince1970 - Date().timeIntervalSince1970) <= 0{
                                    HStack{
                                        Text("已截止")
                                            .foregroundStyle(Color.creamBrown)
                                            .padding(.bottom, 0.5)
                                            .padding(.horizontal, -3)
                                            .bold()
                                            .font(.system(size: 8))
                                        Spacer()
                                    }
                                }else{
                                    HStack{
                                        Text("将截止")
                                            .foregroundStyle(Color.creamBrown)
                                            .padding(.bottom, 0.5)
                                            .padding(.horizontal, -3)
                                            .bold()
                                            .font(.system(size: 8))
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
//                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                if tododata.isEmpty {
                    Text("这周没有任务")
                        .bold()
                        .foregroundStyle(Color.myBlack)
                }
            }
            .padding(.top, 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct WidgetLineChartView: View {
    var entry: Provider.Entry
    func tomorrowStart() -> Date? {
        let calendar = Calendar.current
        let currentDate = entry.date
        var components = DateComponents()
        components.day = 1
        
        guard let tomorrow = calendar.date(byAdding: components, to: currentDate) else {
            return nil
        }
        
        let startOfDayComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        
        return calendar.date(from: startOfDayComponents)
    }
    
    func getWeekLineChartData(tododata: [TodoData]) -> [lineWeekData]{ // 获取近一个星期的折线图数据
        var lineWeekDataArray: [lineWeekData] = []
        let calendar = Calendar.current
        // 获取星期数字（1代表星期日，2代表星期一，以此类推）
        var weekdayNumber = 0
        if calendar.component(.weekday, from: Date()) == 1{
            weekdayNumber = 7
        }else{
            weekdayNumber = calendar.component(.weekday, from: entry.date) - 1
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
    
    func getWorkingWeekTime(tododata: [TodoData]) -> [workingTimeWeekData]{
        var workingTimeArray: [workingTimeWeekData] = []
        let calendar = Calendar.current
        // 获取星期数字（1代表星期日，2代表星期一，以此类推）
        var weekdayNumber = 0
        if calendar.component(.weekday, from: Date()) == 1{
            weekdayNumber = 7
        }else{
            weekdayNumber = calendar.component(.weekday, from: entry.date) - 1
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
        }else if max >= 60*60 && max < 60*60*24{
            for index in 0..<7 {
                workingTimeArray[index].value = workingTimeArray[index].value / (60*60)
                workingTimeArray[index].range = "H"
            }
            return workingTimeArray
        }else{
            return workingTimeArray
        }
    }
    
    @Query var alltodo: [TodoData]
    @Environment(\.modelContext) var modelContext
    
    var samplelineWeekData: [lineWeekData] = [
        .init(day: "1", value: 44),
        .init(day: "2", value: 70),
        .init(day: "3", value: 66),
        .init(day: "4", value: 77),
        .init(day: "5", value: 49),
        .init(day: "6", value: 89),
        .init(day: "7", value: 92)
    ]
    
    var body: some View {
        Chart{
            ForEach(getWeekLineChartData(tododata: alltodo), id: \.day) { lineData in
                LineMark(x: .value("day", lineData.day),
                         y: .value("total", lineData.value))
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.blackBlue2)
            }
        }
        .chartForegroundStyleScale([
            String(localized: "效率"): Color.blackBlue2,
        ])
    }
}


struct RingShape: Shape {
    var progress: Double = 0.0
    var thickness: CGFloat = 30.0
    var startAngle: Double = -90.0
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.width / 2.0, y: rect.height / 2.0), radius: min(rect.width, rect.height) / 2.0,startAngle: .degrees(startAngle),endAngle: .degrees(360 * progress+startAngle), clockwise: false)
        
        return path.strokedPath(.init(lineWidth: thickness, lineCap: .round))
    }
}

typealias TodoData =  TodoDataSchemaV9.TodoData
typealias UserSetting = TodoDataSchemaV9.UserSetting

enum TodoDataMigrationPlan2: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] {
        [TodoDataSchemaV1.self, TodoDataSchemaV2.self, TodoDataSchemaV3.self, TodoDataSchemaV4.self, TodoDataSchemaV5.self, TodoDataSchemaV6.self, TodoDataSchemaV7.self, TodoDataSchemaV8.self, TodoDataSchemaV9.self]
    }
    static var stages: [MigrationStage]{
        [migrationV1toV2, migrationV2toV3, migrationV3toV4, migrationV4toV5, migrationV5toV6, migrationV6toV7, migrationV7toV8, migrationV8toV9]
    }
    static let migrationV1toV2 = MigrationStage.lightweight(fromVersion: TodoDataSchemaV1.self, toVersion: TodoDataSchemaV2.self)
    static let migrationV2toV3 = MigrationStage.lightweight(fromVersion: TodoDataSchemaV2.self, toVersion: TodoDataSchemaV3.self)
    static let migrationV3toV4 = MigrationStage.lightweight(fromVersion: TodoDataSchemaV3.self, toVersion: TodoDataSchemaV4.self)
    static let migrationV4toV5 = MigrationStage.lightweight(fromVersion: TodoDataSchemaV4.self, toVersion: TodoDataSchemaV5.self)
    static let migrationV5toV6 = MigrationStage.lightweight(fromVersion: TodoDataSchemaV5.self, toVersion: TodoDataSchemaV6.self)
    static let migrationV6toV7 = MigrationStage.lightweight(fromVersion: TodoDataSchemaV6.self, toVersion: TodoDataSchemaV7.self)
    static let migrationV7toV8 = MigrationStage.lightweight(fromVersion: TodoDataSchemaV7.self, toVersion: TodoDataSchemaV8.self)
    static let migrationV8toV9 = MigrationStage.lightweight(fromVersion: TodoDataSchemaV8.self, toVersion: TodoDataSchemaV9.self)
}

struct DeadLineTodoWidget: Widget {
    let kind: String = "DeadLineTodoWidget"
    
    let container: ModelContainer
    
    init() {
        do {
            let config = ModelConfiguration("TodoData", schema: Schema([TodoData.self, UserSetting.self]))
            container = try ModelContainer(
                for: TodoData.self, UserSetting.self,
                migrationPlan: TodoDataMigrationPlan2.self,
                configurations: config)
        } catch {
            fatalError("Failed to initialize model container.")
        }
    }
    

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DeadLineTodoWidgetEntryView(entry: entry)
                .containerBackground(.grayWhite1, for: .widget)
                .modelContainer(container)
        }
        .configurationDisplayName("每日待办")
        .description("展示你的每日待办和完成进度")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    DeadLineTodoWidget()
} timeline: {
    SimpleEntry(date: .now)
}
//
//fileprivate struct ToggleButton: AppIntent {
//    static var title: LocalizedStringResource = .init(stringLiteral: "Toggle's Todo State")
//    
//    @Parameter(title: "Todo ID")
//    var id: String
//    
//    init() {
//        <#code#>
//    }
//    
//    init(id: String) {
//        self.id = id
//    }
//    
//    func perform() async throws -> some IntentResult {
//        return .result()
//    }
//}
