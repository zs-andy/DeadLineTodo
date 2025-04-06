//
//  TodoView.swift
//  DeadLineTodo
//
//  Created by Andy on 2024/1/19.
//

import SwiftUI
import SwiftData
import EventKit
import WidgetKit
import SwiftUIPullToRefresh
import TipKit


extension TodoView {
    @MainActor
    class TodoViewModel: ObservableObject {
        @Published var index_: Int = 0
    }
}

struct TodoView: View {
    @Query var tododata: [TodoData]
    init(sort: SortDescriptor<TodoData>, AddTodoIsPresent: Binding<Bool>, EmergencyNum: Binding<Int>) {
        _tododata = Query(filter: #Predicate {
            $0.todo == true || $0.emergency == true
        }, sort: [sort])
        _AddTodoIsPresent = AddTodoIsPresent
        _EmergencyNum = EmergencyNum
    }
    @Query var usersetting: [UserSetting]
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var store: StoreKitManager
    @Binding var AddTodoIsPresent: Bool
    @Binding var EmergencyNum: Int
    
    @State var isAddDateAlertPresent: Bool = false
    
    @StateObject private var viewModel = TodoViewModel()
    
    @State var EditTodoIsPresent: Bool = false
    var timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    @State var rowWidth: CGFloat? = nil
    
    @State var isShowingDatePicker = false
    @State var selectedDate = Date()
    @State var allowToTap = false
    
    let reminderService = ReminderService();
    
    let addFirstTaskTip = FirstTaskTip()
    
    let addTaskTip = AddContentTip()
    
    func removeEventToReminders(title: String){
        let eventStore = EKEventStore()
        // 创建一个谓词以查找具有指定标题的提醒事项
        let predicate = eventStore.predicateForReminders(in: nil)
        
        // 指定提醒事项的标题
        let reminderTitleToModify = title

        // 获取提醒事项
        eventStore.fetchReminders(matching: predicate) { (reminders) in
            // 遍历提醒事项列表，找到要修改的提醒事项
            if let matchingReminder = reminders?.first(where: { $0.title == reminderTitleToModify }) {
                // 保存修改
                do {
                    try eventStore.remove(matchingReminder, commit: true)
                    print("提醒事项删除成功")
                } catch {
                    print("提醒事项删除失败: \(error.localizedDescription)")
                }
            } else {
                print("未找到要修改的提醒事项")
            }
        }
    }
    
    func getNeedTime(day: Double, hour: Double, min: Double) -> Double {
        return day*60*60*24 + hour*60*60 + min*60
    }
    
    // 取消待处理通知
    func cancelPendingNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func sendNotification1(todo: TodoData) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = NSLocalizedString("将截止", comment: "")
        notificationContent.subtitle = todo.content

        if getLeftTime(todo: todo) > 0{
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: getLeftTime(todo: todo), repeats: false)
            let req = UNNotificationRequest(identifier: todo.id.uuidString + "1", content: notificationContent, trigger: trigger)
            UNUserNotificationCenter.current().add(req)
        }
        // you could also use...
        // UNCalendarNotificationTrigger(dateMatching: .init(year: 2022, month: 12, day: 10, hour: 0, minute: 0), repeats: true
    }
    
    func sendNotification2(todo: TodoData, day: Double, hour: Double, min: Double) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = NSLocalizedString("已截止", comment: "")
        notificationContent.subtitle = todo.content

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: getLeftTime(todo: todo) + getNeedTime(day: day, hour: hour, min: min), repeats: false)
        // you could also use...
        // UNCalendarNotificationTrigger(dateMatching: .init(year: 2022, month: 12, day: 10, hour: 0, minute: 0), repeats: true)

        let req = UNNotificationRequest(identifier: todo.id.uuidString + "2", content: notificationContent, trigger: trigger)

        UNUserNotificationCenter.current().add(req)
    }
    
    func sendNotification3(todo: TodoData) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = NSLocalizedString("紧急！", comment: "")
        notificationContent.subtitle = todo.content

        if todo.emergencyDate.timeIntervalSince1970 - Date().timeIntervalSince1970 > 0 {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: todo.emergencyDate.timeIntervalSince1970 - Date().timeIntervalSince1970, repeats: false)
            // you could also use...
            // UNCalendarNotificationTrigger(dateMatching: .init(year: 2022, month: 12, day: 10, hour: 0, minute: 0), repeats: true)

            let req = UNNotificationRequest(identifier: todo.id.uuidString + "3", content: notificationContent, trigger: trigger)

            UNUserNotificationCenter.current().add(req)
        }
    }
    
    func sendNotification4(todo: TodoData) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = NSLocalizedString("任务超时", comment: "")
        notificationContent.subtitle = todo.content

        if todo.needTime - todo.lastTime > 0{
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: todo.needTime - todo.lastTime, repeats: false)
            let req = UNNotificationRequest(identifier: todo.id.uuidString + "4", content: notificationContent, trigger: trigger)
            UNUserNotificationCenter.current().add(req)
        }
        // you could also use...
        // UNCalendarNotificationTrigger(dateMatching: .init(year: 2022, month: 12, day: 10, hour: 0, minute: 0), repeats: true
    }
    
    func getDateString(date: Date) -> String { //转换格式
        let dformatter = DateFormatter()
        dformatter.dateFormat = NSLocalizedString("yyyy年MM月dd日", comment: "")
        return dformatter.string(from: date)
    }
    func getTimeString(date: Date) -> String { //转换格式
        let dformatter = DateFormatter()
        dformatter.dateFormat = "HH:mm"
        return dformatter.string(from: date)
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
        let leftTime = todo.endDate.timeIntervalSince1970 - Date().timeIntervalSince1970 - todo.needTime + todo.actualFinishTime
        return max(leftTime, 0)
    }
    
    func getOffset(todo: TodoData, width: Double) -> CGFloat {
        let offset = (Date().timeIntervalSince1970 - todo.addDate.timeIntervalSince1970) / (todo.endDate.timeIntervalSince1970 - todo.addDate.timeIntervalSince1970) * width
        return offset
    }
    
    func getSize(todo: TodoData, width: Double) -> CGFloat {
        let needTime = todo.needTime - todo.actualFinishTime
        let now = Date()
        let total = todo.endDate.timeIntervalSince1970 - now.timeIntervalSince1970
        let size = (Double(needTime) / total) * width
        if size >= 0 && size <= width{
            return size
        }else{
            return width
        }
    }
    
    func location(todo: TodoData, width: Double) -> CGFloat{
        let now = Date()
        let total = todo.endDate.timeIntervalSince1970 - now.timeIntervalSince1970
        let l = ((todo.emergencyDate.timeIntervalSince1970 - now.timeIntervalSince1970) / total)*width
        return l
    }
    
    func getScore(todo: TodoData) -> Int {
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
    
    func done(todo: TodoData, doneDate: Date){
        if todo.addDate.timeIntervalSince1970 <= Date().timeIntervalSince1970{
            if todo.emergency {
                EmergencyNum -= 1
            }
            if todo.doing {
                todo.doing = false
                todo.lastTime = todo.actualFinishTime
                if todo.actualFinishTime < todo.needTime{
                    todo.Day = decomposeSeconds(totalSeconds: todo.needTime - todo.actualFinishTime).days
                    todo.Hour = decomposeSeconds(totalSeconds: todo.needTime - todo.actualFinishTime).hours
                    todo.Min = decomposeSeconds(totalSeconds: todo.needTime - todo.actualFinishTime).minutes
                    todo.Sec = decomposeSeconds(totalSeconds: todo.needTime - todo.actualFinishTime).seconds
                }else{
                    todo.Day = 0
                    todo.Hour = 0
                    todo.Min = 0
                    todo.Sec = 0
                }
            }
            cancelPendingNotification(withIdentifier: todo.id.uuidString + "1")
            cancelPendingNotification(withIdentifier: todo.id.uuidString + "2")
            cancelPendingNotification(withIdentifier: todo.id.uuidString + "3")
            cancelPendingNotification(withIdentifier: todo.id.uuidString + "4")
            removeEventToReminders(title: todo.content)
            todo.doneDate = doneDate
            todo.score = getScore(todo: todo)
            todo.offset = 0
            todo.todo = false
            todo.emergency = false
            todo.done = true
            if todo.repeatTime != 0 {
//                                                        let needTime =
                var repeatTodo: TodoData = TodoData(content: todo.content, repeatTime: todo.repeatTime, priority: todo.priority, endDate: todo.endDate, addDate: Date(), doneDate: Date(), emergencyDate: todo.emergencyDate, startDoingDate: Date(), leftTime: 0,needTime: todo.initialNeedTime, actualFinishTime: 0, lastTime: 0, initialNeedTime: todo.initialNeedTime, Day: decomposeSeconds(totalSeconds: todo.initialNeedTime).days, Hour: decomposeSeconds(totalSeconds: todo.initialNeedTime).hours, Min: decomposeSeconds(totalSeconds: todo.initialNeedTime).minutes, Sec: decomposeSeconds(totalSeconds: todo.initialNeedTime).seconds, todo: true, done: false, emergency: false, doing: false, offset: 0, lastoffset: 0, score: 0, times: todo.times + 1)
                if todo.repeatTime == 1 {
                    repeatTodo.endDate = Date(timeIntervalSince1970: repeatTodo.endDate.timeIntervalSince1970 + 60*60*24)
                    repeatTodo.emergencyDate = Date(timeIntervalSince1970: repeatTodo.emergencyDate.timeIntervalSince1970 + 60*60*24)
                    repeatTodo.addDate = getStartOfDay(startDate: repeatTodo.emergencyDate)
                    while repeatTodo.endDate < Date() {//改为endDate判断
                        repeatTodo.endDate = Date(timeIntervalSince1970: repeatTodo.endDate.timeIntervalSince1970 + 60*60*24)
                        repeatTodo.emergencyDate = Date(timeIntervalSince1970: repeatTodo.emergencyDate.timeIntervalSince1970 + 60*60*24)
                        repeatTodo.addDate = getStartOfDay(startDate: repeatTodo.emergencyDate)
                    }
                    modelContext.insert(repeatTodo)
                }else if todo.repeatTime == 2 {
                    repeatTodo.endDate = Date(timeIntervalSince1970: repeatTodo.endDate.timeIntervalSince1970 + 60*60*24*7)
                    repeatTodo.emergencyDate = Date(timeIntervalSince1970: repeatTodo.emergencyDate.timeIntervalSince1970 + 60*60*24*7)
                    repeatTodo.addDate = getStartOfWeek(startDate: repeatTodo.emergencyDate)
                    while repeatTodo.endDate < Date() {
                        repeatTodo.endDate = Date(timeIntervalSince1970: repeatTodo.endDate.timeIntervalSince1970 + 60*60*24*7)
                        repeatTodo.emergencyDate = Date(timeIntervalSince1970: repeatTodo.emergencyDate.timeIntervalSince1970 + 60*60*24*7)
                        repeatTodo.addDate = getStartOfWeek(startDate: repeatTodo.emergencyDate)
                    }
                    modelContext.insert(repeatTodo)
                }else if todo.repeatTime == 3 {
                    repeatTodo.endDate = Date(timeIntervalSince1970: repeatTodo.endDate.timeIntervalSince1970 + 60*60*24*7*30)
                    repeatTodo.emergencyDate = Date(timeIntervalSince1970: repeatTodo.emergencyDate.timeIntervalSince1970 + 60*60*24*7*30)
                    repeatTodo.addDate = getStartOfMonth(startDate: repeatTodo.emergencyDate)
                    while repeatTodo.endDate < Date() {
                        repeatTodo.endDate = Date(timeIntervalSince1970: repeatTodo.endDate.timeIntervalSince1970 + 60*60*24*7*30)
                        repeatTodo.emergencyDate = Date(timeIntervalSince1970: repeatTodo.emergencyDate.timeIntervalSince1970 + 60*60*24*7*30)
                        repeatTodo.addDate = getStartOfMonth(startDate: repeatTodo.emergencyDate)
                    }
                    modelContext.insert(repeatTodo)
                }
                sendNotification1(todo: repeatTodo)
                sendNotification2(todo: repeatTodo, day: Double(repeatTodo.Day), hour: Double(repeatTodo.Hour), min: Double(repeatTodo.Min))
                sendNotification3(todo: repeatTodo)
                reminderService.addEventToReminders(title: repeatTodo.content, priority: repeatTodo.priority, dueDate: repeatTodo.endDate, remindDate: repeatTodo.emergencyDate, edittodo: todo)
                let time = repeatTodo.Day*24*60*60 + repeatTodo.Hour*60*60 + repeatTodo.Min*60
                addEventToCalendar(title: repeatTodo.content, startDate: repeatTodo.emergencyDate, dueDate: Date(timeIntervalSince1970: repeatTodo.emergencyDate.timeIntervalSince1970 + Double(time)))
            }
            WidgetCenter.shared.reloadAllTimelines()
        }else{
            isAddDateAlertPresent = true
        }
    }
    
    func addEventToCalendar(title: String, startDate: Date, dueDate: Date) {
        let eventStore = EKEventStore()
        
        let newEvent = EKEvent(eventStore: eventStore)
        newEvent.title = title
        newEvent.calendar = eventStore.defaultCalendarForNewEvents
        
        newEvent.startDate = startDate
        newEvent.endDate = dueDate
        
        let alarm = EKAlarm(absoluteDate: startDate)
        newEvent.addAlarm(alarm)
        
        print("add")
        
        do {
            try eventStore.save(newEvent, span: .thisEvent)
            print("Event saved successfully")
        } catch let error {
            print("Event failed with error: \(error.localizedDescription)")
        }
    }

    @State private var now = Date()
    
    func fetchAllReminders(){
        // 创建一个 EventStore 实例
        let eventStore = EKEventStore()
        // 创建提醒事项的搜索谓词（此处为空，表示获取所有提醒事项）
        let predicate = eventStore.predicateForReminders(in: nil)
        
        // 获取提醒事项
        eventStore.fetchReminders(matching: predicate) { (reminders: [EKReminder]?) in
            if let reminders = reminders {
                for reminder in reminders {
                    if reminder.isCompleted == false {
                        print("提醒事项标题: \(reminder.title ?? "")")
                        if let dueDate = reminder.dueDateComponents?.date {
                            print("提醒时间: \(dueDate)")
                            var has = false
                            for todo in tododata {
                                if todo.content == reminder.title {
                                    has = true
                                }
                            }
                            if has == false{
                                let reminderTodo = TodoData(content: reminder.title, repeatTime: 0,priority: reminder.priority, endDate: Date(timeIntervalSince1970: dueDate.timeIntervalSince1970 + 2*60*60), addDate: Date(), doneDate: Date(), emergencyDate: dueDate, startDoingDate: Date(), leftTime: 0,needTime: 2*60*60, actualFinishTime: 0, lastTime: 0, initialNeedTime: 0, Day: 0, Hour: 2, Min: 0, Sec: 0, todo: true, done: false, emergency: false, doing: false, offset: 0, lastoffset: 0, score: 0, times: 0)
                                modelContext.insert(reminderTodo)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func deleteEventFromCalendar(title: String) {
        let eventStore = EKEventStore()
        
        let predicate = eventStore.predicateForEvents(withStart: Date(), end: Date().addingTimeInterval(31 * 24 * 60 * 60), calendars: nil)
        
        let events = eventStore.events(matching: predicate)
        
        for event in events {
            if event.title == title {
                do {
                    try eventStore.remove(event, span: .thisEvent)
                    print("事件删除成功")
                    return
                } catch {
                    print("事件删除失败: \(error.localizedDescription)")
                    return
                }
            }
        }
        
        print("未找到要删除的事件")
    }
    
    func syncCalendarEvents() {
        let eventStore = EKEventStore()
        
        let calendars = eventStore.calendars(for: .event)
        
        for calendar in calendars {
            print("日历名称: \(calendar.title)")
            
            var bool: Bool = false
            for cal in usersetting[0].selectedOptions {
                if cal == calendar.title {
                    bool = true
                }
            }
            
            if bool {
                let startDate = Date()
                let endDate = Date().addingTimeInterval(60*60*24*7*31) // 一个月
                let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
                let events = eventStore.events(matching: predicate)
                
                for event in events {
                    var has = false
                    for todo in tododata {
                        if todo.content == event.title {
                            has = true
                        }
                    }
                    if has == false{
                        let needtime = event.endDate.timeIntervalSince1970 - event.startDate.timeIntervalSince1970
                        let reminderTodo = TodoData(content: event.title, repeatTime: 0,priority: 0, endDate: event.endDate, addDate: Date(), doneDate: Date(), emergencyDate: event.startDate, startDoingDate: Date(), leftTime: 0,needTime: needtime, actualFinishTime: 0, lastTime: 0, initialNeedTime: needtime, Day: decomposeSeconds(totalSeconds: needtime).days, Hour: decomposeSeconds(totalSeconds: needtime).hours, Min: decomposeSeconds(totalSeconds: needtime).minutes, Sec: decomposeSeconds(totalSeconds: needtime).seconds, todo: true, done: false, emergency: false, doing: false, offset: 0, lastoffset: 0, score: 0, times: 0)
                        modelContext.insert(reminderTodo)
                    }
                }
            }
        }
    }

        
    var body: some View {
        VStack{
            HStack{
                Text("待办")
                    .font(.system(size: 30))
                    .bold()
                    .padding(20)
                    .foregroundStyle(Color.myBlack)
                Spacer()
            }
            RefreshableScrollView(loadingViewBackgroundColor: Color.grayWhite1, onRefresh: { done in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if usersetting[0].reminder {
                        fetchAllReminders()
                    }
                    if usersetting[0].calendar{
                        syncCalendarEvents()
                    }
                  self.now = Date()
                  done()
                }
            }){
                LazyVStack{
                    TipView(addFirstTaskTip)
                        .padding(.horizontal)
                    TipView(addTaskTip)
                        .padding(.horizontal)
                    ForEach(tododata.indices, id: \.self){index in
//                        if tododata[index].todo {
                        if tododata.indices.contains(index) {
                            ZStack{
                                HStack(){
                                    Spacer()
                                    ZStack(alignment: .trailing){
//                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
//                                            .fill(Color.grayWhite3)
                                        HStack{
                                            Spacer()
                                            Button(action: {
                                                if tododata.indices.contains(index) && allowToTap {
                                                    cancelPendingNotification(withIdentifier: tododata[index].id.uuidString + "1")
                                                    cancelPendingNotification(withIdentifier: tododata[index].id.uuidString + "2")
                                                    cancelPendingNotification(withIdentifier: tododata[index].id.uuidString + "3")
                                                    cancelPendingNotification(withIdentifier: tododata[index].id.uuidString + "4")
                                                    removeEventToReminders(title: tododata[index].content)
                                                    deleteEventFromCalendar(title: tododata[index].content)
                                                    if tododata[index].emergency {
                                                        EmergencyNum -= 1
                                                    }
                                                    modelContext.delete(tododata[index])
                                                }
                                                WidgetCenter.shared.reloadAllTimelines()
                                            }){
                                                ZStack{
                                                    Circle()
                                                        .foregroundStyle(.thinMaterial)
                                                        .frame(width: 40, height: 40)
                                                    Image(systemName: "trash")
                                                        .padding(5)
                                                        .bold()
                                                        .font(.system(size: 20))
                                                        .foregroundStyle(Color.red)
                                                }
                                            }
                                            Button(action: {
                                                if tododata.indices.contains(index) && allowToTap{
                                                    withAnimation(.default){
                                                        if tododata[index].addDate.timeIntervalSince1970 <= Date().timeIntervalSince1970{
                                                            if tododata[index].doing {
                                                                tododata[index].doing = false
                                                                cancelPendingNotification(withIdentifier: tododata[index].id.uuidString + "4")
                                                                tododata[index].lastTime = tododata[index].actualFinishTime
                                                                if tododata[index].actualFinishTime < tododata[index].needTime{
                                                                    tododata[index].Day = decomposeSeconds(totalSeconds: tododata[index].needTime - tododata[index].actualFinishTime).days
                                                                    tododata[index].Hour = decomposeSeconds(totalSeconds: tododata[index].needTime - tododata[index].actualFinishTime).hours
                                                                    tododata[index].Min = decomposeSeconds(totalSeconds: tododata[index].needTime - tododata[index].actualFinishTime).minutes
                                                                    tododata[index].Sec = decomposeSeconds(totalSeconds: tododata[index].needTime - tododata[index].actualFinishTime).seconds
                                                                }else{
                                                                    tododata[index].Day = 0
                                                                    tododata[index].Hour = 0
                                                                    tododata[index].Min = 0
                                                                    tododata[index].Sec = 0
                                                                }
                                                                sendNotification1(todo: tododata[index])
                                                            }else{
                                                                tododata[index].doing = true
                                                                tododata[index].startDoingDate = Date()
                                                                tododata[index].actualFinishTime = 0
                                                                sendNotification4(todo: tododata[index])
                                                                cancelPendingNotification(withIdentifier: tododata[index].id.uuidString + "1")
                                                            }
                                                        }else{
                                                            isAddDateAlertPresent = true
                                                        }
                                                    }
                                                }
                                            }){
                                                ZStack{
                                                    Circle()
                                                        .foregroundStyle(.thinMaterial)
                                                        .frame(width: 40, height: 40)
                                                    if tododata[index].doing {
                                                        Image(systemName: "pause.circle")
                                                            .padding(5)
                                                            .bold()
                                                            .font(.system(size: 20))
                                                            .foregroundStyle(Color.blackBlue2)
                                                        
                                                    }else{
                                                        Image(systemName: "restart.circle")
                                                            .padding(5)
                                                            .bold()
                                                            .font(.system(size: 20))
                                                            .foregroundStyle(Color.blackBlue2)
                                                    }
                                                }
                                            }
                                            Button(action: {
                                                withAnimation(.default){
                                                    if tododata.indices.contains(index) && allowToTap{
                                                        done(todo: tododata[index], doneDate: Date())
                                                    }
                                                }
                                                WidgetCenter.shared.reloadAllTimelines()
                                            }){
                                                ZStack{
                                                    Circle()
                                                        .foregroundStyle(.thinMaterial)
                                                        .frame(width: 40, height: 40)
                                                    Image(systemName: "checkmark.circle")
                                                        .padding(.vertical, 5)
                                                        .bold()
                                                        .font(.system(size: 20))
                                                        .foregroundStyle(Color.blackBlue2)
                                                }
                                            }
                                            .contextMenu {
                                                Button(action: {
                                                    isShowingDatePicker.toggle()
                                                    viewModel.index_ = index
                                                }) {
                                                    Text("选择日期和时间")
                                                    Image(systemName: "calendar")
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 5)
                                    }
                                    .offset(x: -2)
                                }
                                ZStack(){ //卡片
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(Color.grayWhite2)
                                    Button(action: {
                                        viewModel.index_ = index
                                        EditTodoIsPresent = true
                                    }){
                                        ZStack(alignment: .topLeading){
                                            if getSize(todo: tododata[index], width: rowWidth ?? 0) != rowWidth{
                                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                    .fill(Color.grayWhite2)
                                                Rectangle()
                                                    .fill(Color.creamPink)
                                                    .frame(width: getSize(todo: tododata[index], width: rowWidth ?? 0))
                                            }else{
                                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                    .fill(Color.creamPink)
                                            }
                                            Rectangle()
                                                .fill(Color.creamBlue)
                                                .offset(x: location(todo: tododata[index], width: rowWidth ?? 0))
                                                .frame(width: 2)
                                            VStack{
                                                HStack{
                                                    VStack(alignment: .leading){
                                                        if tododata[index].priority == 0{
                                                            Text("\(tododata[index].content)")
                                                                .foregroundStyle(Color.myBlack)
                                                                .multilineTextAlignment(.leading)
                                                                .bold()
                                                                .font(.system(size: 17))
                                                        }else if tododata[index].priority == 1 {
                                                            Text("\(tododata[index].content)!!!")
                                                                .foregroundStyle(Color.myBlack)
                                                                .multilineTextAlignment(.leading)
                                                                .bold()
                                                                .font(.system(size: 17))
                                                        }else if tododata[index].priority == 5 {
                                                            Text("\(tododata[index].content)!!")
                                                                .foregroundStyle(Color.myBlack)
                                                                .multilineTextAlignment(.leading)
                                                                .bold()
                                                                .font(.system(size: 17))
                                                        }else if tododata[index].priority == 9 {
                                                            Text("\(tododata[index].content)!")
                                                                .foregroundStyle(Color.myBlack)
                                                                .multilineTextAlignment(.leading)
                                                                .bold()
                                                                .font(.system(size: 17))
                                                        }
                                                        if tododata[index].repeatTime == 1{
                                                            Text("已坚持\(tododata[index].times)天")
                                                                .foregroundStyle(Color.blackGray)
                                                                .bold()
                                                                .font(.system(size: 11))
                                                        }else if tododata[index].repeatTime == 2{
                                                            Text("已坚持\(tododata[index].times)周")
                                                                .foregroundStyle(Color.blackGray)
                                                                .bold()
                                                                .font(.system(size: 11))
                                                        }else if tododata[index].repeatTime == 3{
                                                            Text("已坚持\(tododata[index].times)月")
                                                                .foregroundStyle(Color.blackGray)
                                                                .bold()
                                                                .font(.system(size: 11))
                                                        }
                                                        Text("截止日期")
                                                            .foregroundStyle(Color.blackGray)
                                                            .bold()
                                                            .font(.system(size: 10))
                                                            .padding(.top)
                                                        HStack{
                                                            Text("\(getDateString(date: tododata[index].endDate)) \(getTimeString(date: tododata[index].endDate))")
                                                                .foregroundStyle(Color.blackGray)
                                                                .multilineTextAlignment(.leading)
                                                                .bold()
                                                                .font(.system(size: 12))
                                                        }
                                                    }
                                                    Spacer()
                                                    VStack(alignment: .trailing){
                                                        Text("剩余所需时间")
                                                            .foregroundStyle(Color.blackGray)
                                                            .bold()
                                                            .padding(.horizontal, -2)
                                                            .font(.system(size: 10))
                                                        HStack{
                                                            if tododata[index].Day != 0{
                                                                Text("\(tododata[index].Day)天")
                                                                    .foregroundStyle(Color.blackGray)
                                                                    .padding(.bottom, 0.5)
                                                                    .padding(.horizontal, -3)
                                                                    .bold()
                                                                    .font(.system(size: 13))
                                                            }
                                                            if tododata[index].Hour != 0 {
                                                                Text("\(tododata[index].Hour)时")
                                                                    .foregroundStyle(Color.blackGray)
                                                                    .padding(.bottom, 0.5)
                                                                    .padding(.horizontal, -3)
                                                                    .bold()
                                                                    .font(.system(size: 13))
                                                            }
                                                            if tododata[index].Min != 0{
                                                                Text("\(tododata[index].Min)分")
                                                                    .foregroundStyle(Color.blackGray)
                                                                    .padding(.bottom, 0.5)
                                                                    .padding(.horizontal, -3)
                                                                    .bold()
                                                                    .font(.system(size: 13))
                                                            }
                                                        }
                                                        Spacer()
                                                        if tododata[index].doing{
                                                            Text("正在进行")
                                                                .foregroundStyle(Color.blackGray)
                                                                .bold()
                                                                .padding(.horizontal, -2)
                                                                .font(.system(size: 10))
                                                            if tododata[index].actualFinishTime <= tododata[index].needTime{
                                                                HStack{
                                                                    if decomposeSeconds(totalSeconds: tododata[index].actualFinishTime).days != 0{
                                                                        Text("\(decomposeSeconds(totalSeconds: tododata[index].leftTime).days)天")
                                                                            .foregroundStyle(Color.blackGray)
                                                                            .padding(.bottom, 0.5)
                                                                            .padding(.horizontal, -3)
                                                                            .bold()
                                                                            .font(.system(size: 13))
                                                                    }
                                                                    if decomposeSeconds(totalSeconds: tododata[index].actualFinishTime).hours != 0 {
                                                                        Text("\(decomposeSeconds(totalSeconds: tododata[index].actualFinishTime).hours)时")
                                                                            .foregroundStyle(Color.blackGray)
                                                                            .padding(.bottom, 0.5)
                                                                            .padding(.horizontal, -3)
                                                                            .bold()
                                                                            .font(.system(size: 13))
                                                                    }
                                                                    if decomposeSeconds(totalSeconds: tododata[index].actualFinishTime).minutes != 0{
                                                                        Text("\(decomposeSeconds(totalSeconds: tododata[index].actualFinishTime).minutes)分")
                                                                            .foregroundStyle(Color.blackGray)
                                                                            .padding(.bottom, 0.5)
                                                                            .padding(.horizontal, -3)
                                                                            .bold()
                                                                            .font(.system(size: 13))
                                                                    }
                                                                }
                                                            }else{
                                                                Text("任务超时")
                                                                    .foregroundStyle(Color.creamBrown)
                                                                    .padding(.bottom, 0.5)
                                                                    .padding(.horizontal, -3)
                                                                    .bold()
                                                                    .font(.system(size: 13))
                                                            }
                                                        }else{
                                                            Text("剩余时间")
                                                                .foregroundStyle(Color.blackGray)
                                                                .bold()
                                                                .padding(.horizontal, -2)
                                                                .font(.system(size: 10))
                                                            
                                                            if getLeftTime(todo: tododata[index]) > 0{
                                                                HStack{
                                                                    if decomposeSeconds(totalSeconds: tododata[index].leftTime).days != 0{
                                                                        Text("\(decomposeSeconds(totalSeconds: tododata[index].leftTime).days)天")
                                                                            .foregroundStyle(Color.blackGray)
                                                                            .padding(.bottom, 0.5)
                                                                            .padding(.horizontal, -3)
                                                                            .bold()
                                                                            .font(.system(size: 13))
                                                                    }
                                                                    if decomposeSeconds(totalSeconds: tododata[index].leftTime).hours != 0 {
                                                                        Text("\(decomposeSeconds(totalSeconds: tododata[index].leftTime).hours)时")
                                                                            .foregroundStyle(Color.blackGray)
                                                                            .padding(.bottom, 0.5)
                                                                            .padding(.horizontal, -3)
                                                                            .bold()
                                                                            .font(.system(size: 13))
                                                                    }
                                                                    if decomposeSeconds(totalSeconds: tododata[index].leftTime).minutes != 0{
                                                                        Text("\(decomposeSeconds(totalSeconds: tododata[index].leftTime).minutes)分")
                                                                            .foregroundStyle(Color.blackGray)
                                                                            .padding(.bottom, 0.5)
                                                                            .padding(.horizontal, -3)
                                                                            .bold()
                                                                            .font(.system(size: 13))
                                                                    }
                                                                }
                                                            }else if (tododata[index].endDate.timeIntervalSince1970 - Date().timeIntervalSince1970) <= 0{
                                                                Text("已截止")
                                                                    .foregroundStyle(Color.creamBrown)
                                                                    .padding(.bottom, 0.5)
                                                                    .padding(.horizontal, -3)
                                                                    .bold()
                                                                    .font(.system(size: 13))
                                                            }else{
                                                                Text("将截止")
                                                                    .foregroundStyle(Color.creamBrown)
                                                                    .padding(.bottom, 0.5)
                                                                    .padding(.horizontal, -3)
                                                                    .bold()
                                                                    .font(.system(size: 13))
                                                            }
                                                        }
                                                    }
                                                }
                                                .padding()
                                            }
                                        }
                                        .simultaneousGesture(
                                            DragGesture()
                                                .onChanged { gesture in
                                                    if gesture.translation.width < 0 || tododata[index].lastoffset != 0{
                                                        allowToTap = false
                                                        withAnimation(.linear(duration: 0.1)){
                                                            tododata[index].offset = tododata[index].lastoffset + gesture.translation.width
                                                        }
                                                    }
                                                }
                                                .onEnded { gesture in
                                                    if tododata.indices.contains(index) {
                                                        if tododata[index].offset <= -70{
                                                            withAnimation(.smooth(duration: 0.4)){
                                                                if tododata.indices.contains(index) {
                                                                    tododata[index].offset = -160
                                                                    tododata[index].lastoffset = -160
                                                                }
                                                                allowToTap = true
                                                            }
                                                        }else {
                                                            withAnimation(.smooth(duration: 0.4)){
                                                                tododata[index].offset = 0
                                                                tododata[index].lastoffset = 0
                                                            }
                                                        }
                                                        EditTodoIsPresent = false
                                                    }
                                                }
                                        )
                                    }
                                }
                                .background(GeometryReader { geometry in
                                                    Color.clear.onAppear {
                                                        // 在 onAppear 中获取控件的宽度
                                                        rowWidth = geometry.size.width
                                                    }
                                                    .onChange(of: geometry.size.width) { oldVlue, newValue in
                                                        // 当宽度发生变化时更新 rowWidth
                                                        rowWidth = newValue
                                                    }
                                                })
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .offset(x: tododata[index].offset)
                            }
                            .padding(.top)
                            .alert(isPresented: $isAddDateAlertPresent) {
                                Alert(title: Text("提醒"), message: Text("已完成的任务"), dismissButton: .default(Text("确定")){
                                    isAddDateAlertPresent = false
                                })
                            }
                            .navigationTitle("编辑任务")
                                            .fullScreenCover(isPresented: $EditTodoIsPresent, content: {// 模态跳转
                                                if tododata.indices.contains(viewModel.index_) {
                                                    EditTodoView(EditTodoIsPresent: $EditTodoIsPresent, edittodo: tododata[viewModel.index_])
                                                } else {
                                                    Text("无效的待办事项")
                                                }
                                            })
                            .onReceive(timer) { _ in
                                // 计时器触发时更新时间
                                if tododata.indices.contains(index) {
                                    if EditTodoIsPresent == false && AddTodoIsPresent == false && tododata[index].done == false{
                                        if tododata[index].doing{
                                            tododata[index].actualFinishTime = tododata[index].lastTime + Date().timeIntervalSince1970 - tododata[index].startDoingDate.timeIntervalSince1970
                                        }
                                        tododata[index].leftTime = getLeftTime(todo: tododata[index])
                                        if Date().timeIntervalSince1970 >= tododata[index].emergencyDate.timeIntervalSince1970 {
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
                            .onAppear{
                                if tododata.indices.contains(index) {
                                    if EditTodoIsPresent == false && AddTodoIsPresent == false && tododata[index].done == false{
                                        if tododata[index].doing{
                                            tododata[index].actualFinishTime = tododata[index].lastTime + Date().timeIntervalSince1970 - tododata[index].startDoingDate.timeIntervalSince1970
                                        }
                                        tododata[index].leftTime = getLeftTime(todo: tododata[index])
                                        if Date().timeIntervalSince1970 >= tododata[index].emergencyDate.timeIntervalSince1970 {
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
                        } else {
                            Text("无效的待办事项")
                        }
//                        }
                        if isShowingDatePicker && viewModel.index_ == index{
                            VStack {
                                DatePicker("选择日期和时间", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(GraphicalDatePickerStyle())
                                    .foregroundStyle(Color.myBlack)
//                                        .labelsHidden()
                                    .padding()
                                    .accentColor(.blackBlue2)
                                Button("完成") {
                                    withAnimation(.default){
                                        done(todo: tododata[index], doneDate: selectedDate)
                                        isShowingDatePicker = false
                                    }
                                }
                                .foregroundStyle(Color.blackBlue2)
                                .bold()
                                .padding()
                            }
                            .background(Color.white)
                            .cornerRadius(15)
//                                .shadow(radius: 30)
                            .padding()
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 150)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if usersetting[0].reminder {
                    fetchAllReminders()
                }
                if usersetting[0].calendar{
                    syncCalendarEvents()
                }
              self.now = Date()
            }
        }
    }

}
