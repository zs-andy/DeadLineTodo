//
//  AddTodoView.swift
//  DeadLineTodo
//
//  Created by Andy on 2024/1/20.
//

import SwiftUI
import SwiftData
import UserNotifications
import EventKit
import WidgetKit
import TipKit

struct AddTodoView: View {
    
    @State var tomorrowDate: Date = Date(timeIntervalSince1970: Date().timeIntervalSince1970 + TimeInterval(24*60*60))
    
    @Binding var AddTodoIsPresent: Bool
    @Binding var isActionInProgress: Bool
    @Environment(\.modelContext) var modelContext
    @Query var tododata: [TodoData]
    @Query var userSetting: [UserSetting]
    @State var addtodo: TodoData
    @State var selectedHours: Int = 2
    @State var selectedMinutes: Int = 0
    @State var selectedDays: Int = 0
    @State var selectedPriority: Int = 0
    @State var selectedCycle: Int = 0
    
    @State private var calendarId: Int = 0
    @State private var calendar2Id: Int = 0
    
    @State var showAlert = false
    @State var showAlertEndTime = false
    @State var showAlertEmergencyTime = false
    @State var showAlertNeedTime = false
    @State var priority:[String] = ["无","高","中","低"]
    @State var cycle:[String] = ["无","天","周","月"]
    @State var showPurchaseAlert = false
    @State var isStorePresent = false
    
    @State var emergencyTime: Date = Date()
    
    @EnvironmentObject var store: StoreKitManager

    
    let enter:LocalizedStringKey = "请输入任务内容"
    
    let setStartTimeTip = SetStartTimeTip()
    let setDeadlineTip = SetDeadlineTip()
    let setDurationTip = SetDurationTip()
    
    func addEventToReminders(title: String, priority: Int, dueDate: Date, remindDate: Date){
        let eventStore = EKEventStore()
        let newEvent = EKReminder(eventStore: eventStore)

        newEvent.title = title
        newEvent.calendar = eventStore.defaultCalendarForNewReminders()
        if priority == 0 {
            newEvent.priority = 0
            addtodo.priority = 0
        }else if priority == 1{
            newEvent.priority = 1
            addtodo.priority = 1
        }else if priority == 2 {
            newEvent.priority = 5
            addtodo.priority = 5
        }else{
            newEvent.priority = 9
            addtodo.priority = 9
        }
        
        let calendar = Calendar.current
        let dueDateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        newEvent.dueDateComponents = dueDateComponents
        
        let alarm = EKAlarm(absoluteDate: remindDate)
        newEvent.addAlarm(alarm)
        
        do {
            try eventStore.save(newEvent, commit: true)
            print(newEvent.priority)
        } catch let error {
            print("Reminder failed with error \(error)")
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
    
    func sendNotification1(todo: TodoData) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = NSLocalizedString("将截止", comment: "")
        notificationContent.subtitle = todo.content

        if getLeftTime(todo: todo) ?? 0 > 0{
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: getLeftTime(todo: todo) ?? 0, repeats: false)
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

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: (getLeftTime(todo: todo) ?? 0) + getNeedTime(day: day, hour: hour, min: min), repeats: false)
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
    
    func getLeftTime(todo: TodoData) -> TimeInterval? {
        let time = selectedDays*60*60*24 + selectedHours*60*60 + selectedMinutes*60
        let leftTime = todo.endDate.timeIntervalSince1970 - Date().timeIntervalSince1970 - Double(time)
        return leftTime
    }
    
    func getNeedTime(day: Double, hour: Double, min: Double) -> Double {
        return day*60*60*24 + hour*60*60 + min*60
    }
    
//    @State var selectedSeconds: Int = 0
    
    var body: some View {
        ZStack{
            VStack{
                VStack{
                    HStack{
                        Text("添加任务")
                            .bold()
                            .font(.system(size: 30))
                            .padding()
                            .foregroundStyle(Color.myBlack)
                        Spacer()
                    }
                    TextField("输入任务内容", text: $addtodo.content)
                        .bold()
                        .padding()
                        .foregroundStyle(Color.blackBlue1)
                        .font(.system(size: 25))
                        .onChange(of: addtodo.content) { _, _ in
                            if #available(iOS 18.0, *) {
                                Task { await SetStartTimeTip.setContentEvent.donate() }
                                Task { await SetStartTimeTip.setContentEvent.donate() }
                            } else {
                                Task { await SetStartTimeTip.setContentEvent.donate() }
                            }
                        }
                }
                .background(Color.creamBlue)
                ScrollView(showsIndicators: false){
                    HStack{
                        Text("任务优先级")
                            .bold()
                            .foregroundStyle(Color.myBlack)
                        Spacer()
                        Picker("f", selection: $selectedPriority) {
                            ForEach(0..<4, id: \.self) { f in
                                Text(LocalizedStringKey(priority[f]))
                                    .bold()
                                    .foregroundStyle(Color.myBlack)
                            }
                        }
                        .accentColor(Color.blackBlue1)
                        .pickerStyle(DefaultPickerStyle())
                    }
                    .padding(.top)
                    .padding(.horizontal)
                    HStack{
                        Text("任务重复周期")
                            .bold()
                            .foregroundStyle(Color.myBlack)
                        Spacer()
                        Picker("f", selection: $selectedCycle) {
                            ForEach(0..<4, id: \.self) { f in
                                Text(LocalizedStringKey(cycle[f]))
                                    .bold()
                                    .foregroundStyle(Color.myBlack)
                            }
                        }
                        .accentColor(Color.blackBlue1)
                        .pickerStyle(DefaultPickerStyle())
                    }
                    .padding(.horizontal)
                    TipView(setStartTimeTip)
                        .padding(.horizontal)
                    DatePicker("开始日期", selection: $addtodo.emergencyDate)
                        .foregroundStyle(Color.myBlack)
                        .datePickerStyle(CompactDatePickerStyle())
//                        .preferredColorScheme(.light)
                        .padding(.horizontal)
                        .bold()
                        .accentColor(.blackBlue2)
                        .id(calendar2Id)
                        .onChange(of: addtodo.emergencyDate) { _, _ in
                            if #available(iOS 18.0, *) {
                                Task { await SetDeadlineTip.setStartTimeEvent.donate() }
                                Task { await SetDeadlineTip.setStartTimeEvent.donate() }
                            } else {
                                Task { await SetDeadlineTip.setStartTimeEvent.donate() }
                            }
                        }
//                    HStack{
//                        Text("如果不做设置，默认开始日期为截止日期减去任务所需时间的两倍")
//                            .font(.system(size: 10))
//                            .foregroundStyle(Color.blackGray)
//                        Spacer()
//                    }
//                    .padding(.horizontal)
                    TipView(setDeadlineTip)
                        .padding(.horizontal)
                    DatePicker("截止日期", selection: $addtodo.endDate)
                        .foregroundStyle(Color.myBlack)
                        .datePickerStyle(CompactDatePickerStyle())
//                        .preferredColorScheme(.light)
                        .padding(.horizontal)
                        .bold()
                        .accentColor(.blackBlue2)
                        .onChange(of: addtodo.endDate) { _, _ in
                            if #available(iOS 18.0, *) {
                                Task { await SetDurationTip.setDeadlineEvent.donate() }
                                Task { await SetDurationTip.setDeadlineEvent.donate() }
                            } else {
                                Task { await SetDurationTip.setDeadlineEvent.donate() }
                            }
                        }
                    TipView(setDurationTip)
                        .padding(.horizontal)
                    HStack{
                        Text("所需时间：")
                            .foregroundStyle(Color.myBlack)
                            .bold()
                            .padding()
                        Spacer()
                    }
                    HStack{
                        HStack {
                            VStack{
                                Text("天")
                                    .foregroundStyle(Color.myBlack)
                                    .bold()
                                Picker("Days", selection: $selectedDays) {
                                    ForEach(0..<32, id: \.self) { day in
                                        Text("\(day)")
                                    }
                                }
                                .id(addtodo.Day)
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 150)
                            }
                            .frame(maxWidth: .infinity)
                            VStack{
                                Text("时")
                                    .foregroundStyle(Color.myBlack)
                                    .bold()
                                Picker("Hours", selection: $selectedHours) {
                                    ForEach(0..<25, id: \.self) { hour in
                                        Text("\(hour)")
                                    }
                                }
                                .id(addtodo.Hour)
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 150)
                            }
                            .frame(maxWidth: .infinity)
                            VStack{
                                Text("分")
                                    .foregroundStyle(Color.myBlack)
                                    .bold()
                                Picker("Minutes", selection: $selectedMinutes) {
                                    ForEach(0..<61, id: \.self) { minute in
                                        Text("\(minute)")
                                    }
                                }
                                .id(addtodo.Min)
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 150)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal)
                    }
                }
                Spacer()
                ZStack{
                    HStack{
                        ZStack{
                            Button(action: {
                                calendarId += 1
                                calendar2Id += 1
                                AddTodoIsPresent = false
                                setDeadlineTip.invalidate(reason: .actionPerformed)
                                setStartTimeTip.invalidate(reason: .actionPerformed)
                                setDurationTip.invalidate(reason: .actionPerformed)
                            }){
                                ZStack{
                                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                                        .fill(Color.creamBlue)
                                        .frame(width: 80, height: 50)
                                    Text("取消")
                                        .bold()
                                        .foregroundStyle(Color.white)
                                }
                            }
                            .padding(.vertical)
                        }
                        .frame(maxWidth: .infinity)
                        ZStack{
                            Button(action: {
                                let time = selectedDays*24*60*60 + selectedHours*60*60 + selectedMinutes*60
                                if ((/*addtodo.emergencyDate.timeIntervalSince1970 < Date().timeIntervalSince1970 ||*/ addtodo.emergencyDate.timeIntervalSince1970 > addtodo.endDate.timeIntervalSince1970 - Double(time)) && addtodo.emergencyDate != emergencyTime) || addtodo.endDate < Date() || getLeftTime(todo: addtodo) ?? 0 <= 0 {
                                    if (/*addtodo.emergencyDate.timeIntervalSince1970 < Date().timeIntervalSince1970 ||*/ addtodo.emergencyDate.timeIntervalSince1970 > addtodo.endDate.timeIntervalSince1970 - Double(time)) && addtodo.emergencyDate != emergencyTime{
                                        calendarId += 1
                                        calendar2Id += 1
                                        showAlert = true
                                        showAlertEmergencyTime = true
                                    }
                                    if addtodo.endDate < Date(){
                                        calendarId += 1
                                        calendar2Id += 1
                                        showAlert = true
                                        showAlertEndTime = true
                                    }else{
                                        if getLeftTime(todo: addtodo) ?? 0 <= 0 {
                                            calendarId += 1
                                            calendar2Id += 1
                                            showAlert = true
                                            showAlertNeedTime = true
                                        }
                                    }
                                } else {
                                    calendarId += 1
                                    calendar2Id += 1
                                    addtodo.Day = selectedDays
                                    addtodo.Hour = selectedHours
                                    addtodo.Min = selectedMinutes
                                    addtodo.needTime = TimeInterval(time)
                                    addtodo.initialNeedTime = TimeInterval(time)
    //                                todo.Sec = selectedSeconds
                                    if addtodo.content == ""{
                                        addtodo.content = NSLocalizedString("请输入任务内容", comment: "")
                                    }
                                    if emergencyTime == addtodo.emergencyDate{
                                        addtodo.emergencyDate = Date(timeIntervalSince1970: addtodo.endDate.timeIntervalSince1970 - Double(time)*2)
                                    }
                                    if selectedCycle == 0{
                                        addtodo.repeatTime = selectedCycle
                                        sendNotification1(todo: addtodo)
                                        sendNotification2(todo: addtodo, day: Double(selectedDays), hour: Double(selectedHours), min: Double(selectedMinutes))
                                        sendNotification3(todo: addtodo)
                                        if userSetting[0].reminder{
                                            addEventToReminders(title: addtodo.content, priority: selectedPriority, dueDate: addtodo.emergencyDate, remindDate: addtodo.emergencyDate)
                                        }else{
                                            if selectedPriority == 0 {
                                                addtodo.priority = 0
                                            }else if selectedPriority == 1{
                                                addtodo.priority = 1
                                            }else if selectedPriority == 2 {
                                                addtodo.priority = 5
                                            }else{
                                                addtodo.priority = 9
                                            }
                                        }
                                        if userSetting[0].calendar {
                                            addEventToCalendar(title: addtodo.content, startDate: addtodo.emergencyDate, dueDate: Date(timeIntervalSince1970: addtodo.emergencyDate.timeIntervalSince1970 + Double(time)))
                                        }
                                        modelContext.insert(addtodo)
                                        AddTodoIsPresent = false
                                    }else{
                                        if store.hasPurchased{
                                            addtodo.repeatTime = selectedCycle
                                            sendNotification1(todo: addtodo)
                                            sendNotification2(todo: addtodo, day: Double(selectedDays), hour: Double(selectedHours), min: Double(selectedMinutes))
                                            sendNotification3(todo: addtodo)
                                            if userSetting[0].reminder{
                                                addEventToReminders(title: addtodo.content, priority: selectedPriority, dueDate: addtodo.emergencyDate, remindDate: addtodo.emergencyDate)
                                            }else{
                                                if selectedPriority == 0 {
                                                    addtodo.priority = 0
                                                }else if selectedPriority == 1{
                                                    addtodo.priority = 1
                                                }else if selectedPriority == 2 {
                                                    addtodo.priority = 5
                                                }else{
                                                    addtodo.priority = 9
                                                }
                                            }
                                            if userSetting[0].calendar {
                                                addEventToCalendar(title: addtodo.content, startDate: addtodo.emergencyDate, dueDate: Date(timeIntervalSince1970: addtodo.emergencyDate.timeIntervalSince1970 + Double(time)))
                                            }
                                            modelContext.insert(addtodo)
                                            AddTodoIsPresent = false
                                        }else{
                                            showAlert = true
                                            showPurchaseAlert = true
                                        }
                                    }
                                }
                                setStartTimeTip.invalidate(reason: .actionPerformed)
                                setDeadlineTip.invalidate(reason: .actionPerformed)
                                setDurationTip.invalidate(reason: .actionPerformed)
                                try? modelContext.save()
                                if #available(iOS 18.0, *) {
                                    Task { await FirstTaskTip.addFirstTaskEvent.donate() }
                                    Task { await FirstTaskTip.addFirstTaskEvent.donate() }
                                } else {
                                    Task { await FirstTaskTip.addFirstTaskEvent.donate() }
                                }
                                WidgetCenter.shared.reloadAllTimelines()
                            }){
                                ZStack{
                                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                                        .fill(Color.blackBlue2)
                                        .frame(width: 80, height: 50)
                                    Text("确定")
                                        .bold()
                                        .foregroundStyle(Color.white)
                                }
                            }
                            .padding(.vertical)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isStorePresent, content: {// 模态跳转
            StoreView(isStorePresent: $isStorePresent)
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.grayWhite1)
        .alert(isPresented: $showAlert) {
            if showAlertEndTime {
                Alert(title: Text("提醒"), message: Text("截止时间在过去"), dismissButton: .default(Text("确定")){
                    showAlertEndTime = false
                    showAlert = false
                })
            }else if showAlertEmergencyTime {
                Alert(title: Text("提醒"), message: Text("开始时间不在允许范围内"), dismissButton: .default(Text("确定")){
                    showAlertEmergencyTime = false
                    showAlert = false
                })
            }else if showAlertNeedTime{
                Alert(title: Text("提醒"), message: Text("任务所需时间超过截止时间"), dismissButton: .default(Text("确定")){
                    showAlertNeedTime = false
                    showAlert = false
                })
            }else{
                Alert(title: Text("提醒"), message: Text("购买高级功能解锁重复任务功能"), dismissButton: .default(Text("确定")){
                    showPurchaseAlert = false
                    showAlert = false
                    isStorePresent = true
                })
            }
        }
    }
}

//#Preview {
//    AddTodoView()
//}
