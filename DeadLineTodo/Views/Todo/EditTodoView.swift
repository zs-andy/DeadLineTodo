//
//  EditTodoView.swift
//  DeadLineTodo
//
//  Edit existing todo view
//

import SwiftUI
import SwiftData
import WidgetKit

struct EditTodoView: View {
    
    // MARK: - Properties
    
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSetting]
    
    @State var todo: TodoData
    @State private var selectedPriority = 0
    @State private var selectedCycle = 0
    @State private var calendarId = 0
    @State private var calendar2Id = 0
    @State private var cancelTime = 0
    
    // 原始值（用于取消时恢复）
    @State private var originalTitle = ""
    @State private var originalDay = 0
    @State private var originalHour = 0
    @State private var originalMin = 0
    @State private var originalEmergencyDate = Date()
    @State private var originalEndDate = Date()
    @State private var originalPriority = 0
    @State private var originalRepeatTime = 0
    
    @State private var showAlert = false
    @State private var alertType: AlertType = .none
    
    private let priority = ["无", "高", "中", "低"]
    private let cycle = ["无", "天", "周", "月"]
    
    private let notificationService = NotificationService.shared
    private let reminderService = ReminderService.shared
    private let calendarService = CalendarService.shared
    private let todoService = TodoService.shared
    
    enum AlertType { case none, endTime, emergencyTime, needTime }

    // MARK: - Body
    
    var body: some View {
        ZStack {
            VStack {
                headerView
                formContent
                bottomButtons
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.grayWhite1)
        .onAppear(perform: loadOriginalValues)
        .alert(Text("提醒"), isPresented: $showAlert) {
            Button("确定") { alertType = .none }
        } message: {
            switch alertType {
            case .endTime: Text("截止时间在过去")
            case .emergencyTime: Text("开始时间不在允许范围内")
            case .needTime: Text("任务所需时间超过截止时间")
            case .none: Text("")
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack {
            HStack {
                Text(LocalizedStringKey("编辑任务"))
                    .bold()
                    .font(.system(size: 30))
                    .padding()
                    .foregroundStyle(Color.myBlack)
                Spacer()
            }
            
            HStack {
                TextField(LocalizedStringKey("输入任务内容"), text: $todo.content)
                    .bold()
                    .padding()
                    .foregroundStyle(Color.blackBlue1)
                    .font(.system(size: 25))
                
                headerActionButton
            }
        }
        .background(Color.creamBlue)
    }
    
    @ViewBuilder
    private var headerActionButton: some View {
        if todo.done {
            // 撤销完成按钮
            Button {
                notificationService.sendNotifications(for: todo)
                reminderService.addReminder(for: todo)
                todo.done = false
                todo.todo = true
                isPresented = false
            } label: {
                smallButton(text: "未完成")
            }
            .padding(.horizontal)
        } else if todo.repeatTime != 0 && cancelTime == 0 {
            // 取消重复按钮
            Button {
                cancelTime += 1
                todo.times = 0
                notificationService.cancelAllNotifications(for: todo)
                todoService.calculateNextRepeat(for: &todo, repeatTime: todo.repeatTime)
                notificationService.sendNotifications(for: todo)
                isPresented = false
            } label: {
                smallButton(text: "取消")
            }
            .padding(.horizontal)
        }
    }
    
    private func smallButton(text: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color.blackBlue2)
                .frame(width: 50, height: 35)
            Text(LocalizedStringKey(text))
                .bold()
                .foregroundStyle(.white)
                .font(.system(size: 12))
        }
    }

    // MARK: - Form Content
    
    private var formContent: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                pickerRow(title: "任务优先级", selection: $selectedPriority, options: priority)
                pickerRow(title: "任务重复周期", selection: $todo.repeatTime, options: cycle)
                
                DatePicker(LocalizedStringKey("开始日期"), selection: $todo.emergencyDate)
                    .foregroundStyle(Color.myBlack)
                    .datePickerStyle(.compact)
                    .padding(.horizontal)
                    .bold()
                    .accentColor(.blackBlue2)
                    .id(calendar2Id)
                
                DatePicker(LocalizedStringKey("截止日期"), selection: $todo.endDate)
                    .foregroundStyle(Color.myBlack)
                    .datePickerStyle(.compact)
                    .padding(.horizontal)
                    .bold()
                    .accentColor(.blackBlue2)
                    .id(calendarId)
                
                durationPicker
            }
        }
    }
    
    private func pickerRow(title: String, selection: Binding<Int>, options: [String]) -> some View {
        HStack {
            Text(LocalizedStringKey(title))
                .bold()
                .foregroundStyle(Color.myBlack)
            Spacer()
            Picker("", selection: selection) {
                ForEach(0..<options.count, id: \.self) { i in
                    Text(LocalizedStringKey(options[i]))
                        .bold()
                        .foregroundStyle(Color.myBlack)
                }
            }
            .accentColor(Color.blackBlue1)
            .pickerStyle(.menu)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var durationPicker: some View {
        VStack {
            HStack {
                Text(LocalizedStringKey("所需时间："))
                    .foregroundStyle(Color.myBlack)
                    .bold()
                    .padding()
                Spacer()
            }
            
            HStack {
                durationColumn(title: "天", selection: $todo.Day, range: 0..<32)
                durationColumn(title: "时", selection: $todo.Hour, range: 0..<25)
                durationColumn(title: "分", selection: $todo.Min, range: 0..<61)
            }
            .padding(.horizontal)
        }
    }
    
    private func durationColumn(title: String, selection: Binding<Int>, range: Range<Int>) -> some View {
        VStack {
            Text(LocalizedStringKey(title))
                .foregroundStyle(Color.myBlack)
                .bold()
            Picker(title, selection: selection) {
                ForEach(range, id: \.self) { Text("\($0)") }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Bottom Buttons
    
    private var bottomButtons: some View {
        HStack {
            Button { cancel() } label: {
                buttonLabel(text: "取消", color: Color.creamBlue)
            }
            .frame(maxWidth: .infinity)
            
            Button { confirm() } label: {
                buttonLabel(text: "确定", color: Color.blackBlue2)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical)
    }
    
    private func buttonLabel(text: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(color)
                .frame(width: 80, height: 50)
            Text(LocalizedStringKey(text))
                .bold()
                .foregroundStyle(.white)
        }
    }

    // MARK: - Actions
    
    private func loadOriginalValues() {
        originalTitle = todo.content
        originalDay = todo.Day
        originalHour = todo.Hour
        originalMin = todo.Min
        originalEmergencyDate = todo.emergencyDate
        originalEndDate = todo.endDate
        originalPriority = todo.priority
        originalRepeatTime = todo.repeatTime
        
        selectedPriority = switch todo.priority {
        case 0: 0
        case 1: 1
        case 5: 2
        default: 3
        }
    }
    
    private func cancel() {
        calendarId += 1
        calendar2Id += 1
        
        // 恢复原始值
        todo.content = originalTitle
        todo.Day = originalDay
        todo.Hour = originalHour
        todo.Min = originalMin
        todo.emergencyDate = originalEmergencyDate
        todo.endDate = originalEndDate
        todo.priority = originalPriority
        todo.repeatTime = originalRepeatTime
        
        isPresented = false
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func confirm() {
        let needTime = TimeInterval.from(days: todo.Day, hours: todo.Hour, minutes: todo.Min)
        let leftTime = todoService.getLeftTime(for: todo)
        
        // 验证
        if !validate(needTime: needTime, leftTime: leftTime) { return }
        
        // 更新任务
        updateTodo(needTime: needTime)
        
        isPresented = false
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func validate(needTime: TimeInterval, leftTime: TimeInterval) -> Bool {
        let emergencyChanged = todo.emergencyDate != originalEmergencyDate
        let endDateChanged = todo.endDate != originalEndDate
        let emergencyInvalid = todo.emergencyDate > todo.endDate.addingTimeInterval(-needTime)
        let totalTime = todo.endDate.timeIntervalSince1970 - todo.addDate.timeIntervalSince1970
        
        if (emergencyInvalid && emergencyChanged) ||
           (todo.endDate < Date() && endDateChanged) ||
           (leftTime <= 0 && totalTime < needTime) {
            
            calendarId += 1
            calendar2Id += 1
            showAlert = true
            
            if emergencyInvalid && emergencyChanged {
                alertType = .emergencyTime
                todo.emergencyDate = originalEmergencyDate
            } else if todo.endDate < Date() && endDateChanged {
                alertType = .endTime
                todo.endDate = originalEndDate
            } else {
                alertType = .needTime
                todo.Day = originalDay
                todo.Hour = originalHour
                todo.Min = originalMin
            }
            return false
        }
        return true
    }
    
    private func updateTodo(needTime: TimeInterval) {
        calendarId += 1
        calendar2Id += 1
        
        if todo.content.isEmpty {
            todo.content = NSLocalizedString("请输入任务内容", comment: "")
        }
        
        todo.needTime = todo.actualFinishTime + needTime
        todo.initialNeedTime = needTime
        todo.Sec = 0
        
        // 取消旧通知
        for i in 0..<4 {
            notificationService.cancelNotification(id: todo.id.uuidString + String(i))
        }
        
        // 发送新通知
        if todo.doing {
            notificationService.sendOvertimeNotification(for: todo)
        }
        notificationService.sendNotifications(for: todo)
        
        // 更新提醒事项
        if !userSettings.isEmpty && userSettings[0].reminder {
            reminderService.editReminder(
                oldTitle: originalTitle,
                newTitle: todo.content,
                priority: selectedPriority,
                dueDate: todo.emergencyDate,
                remindDate: todo.emergencyDate,
                todo: todo
            )
        } else {
            reminderService.removeReminder(title: originalTitle)
            todo.priority = [0, 1, 5, 9][min(selectedPriority, 3)]
        }
        
        // 更新日历
        if !userSettings.isEmpty && userSettings[0].calendar {
            calendarService.editEvent(
                oldTitle: originalTitle,
                newTitle: todo.content,
                startDate: todo.emergencyDate,
                endDate: Date(timeIntervalSince1970: todo.emergencyDate.timeIntervalSince1970 + needTime)
            )
        } else {
            calendarService.deleteEvent(title: originalTitle)
        }
    }
    
}
