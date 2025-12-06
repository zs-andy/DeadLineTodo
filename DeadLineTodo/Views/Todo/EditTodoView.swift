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
    
    // 编辑页主题色 - 使用灰色系搭配粉色
    private let themeColor = Color.blackGray
    
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
                    .foregroundStyle(themeColor)
                    .font(.system(size: 25))
                
                headerActionButton
            }
        }
        .background(Color.creamPink)
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
                .fill(themeColor)
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
            VStack(spacing: 16) {
                prioritySelector
                cycleSelector
                
                DatePicker(LocalizedStringKey("开始日期"), selection: $todo.emergencyDate)
                    .foregroundStyle(Color.myBlack)
                    .datePickerStyle(.compact)
                    .padding(.horizontal)
                    .bold()
                    .accentColor(themeColor)
                    .id(calendar2Id)
                
                DatePicker(LocalizedStringKey("截止日期"), selection: $todo.endDate)
                    .foregroundStyle(Color.myBlack)
                    .datePickerStyle(.compact)
                    .padding(.horizontal)
                    .bold()
                    .accentColor(themeColor)
                    .id(calendarId)
                
                improvedDurationPicker
            }
        }
    }
    
    // 优先级选择器 - 使用按钮组
    private var prioritySelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey("任务优先级"))
                .bold()
                .foregroundStyle(Color.myBlack)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                ForEach(0..<priority.count, id: \.self) { index in
                    Button {
                        selectedPriority = index
                    } label: {
                        Text(LocalizedStringKey(priority[index]))
                            .bold()
                            .font(.system(size: 15))
                            .foregroundStyle(selectedPriority == index ? .white : Color.myBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedPriority == index ? themeColor : Color.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedPriority == index ? themeColor : Color.gray.opacity(0.3), lineWidth: 1.5)
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 10)
    }
    
    // 重复周期选择器 - 使用按钮组
    private var cycleSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey("任务重复周期"))
                .bold()
                .foregroundStyle(Color.myBlack)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                ForEach(0..<cycle.count, id: \.self) { index in
                    Button {
                        todo.repeatTime = index
                    } label: {
                        Text(LocalizedStringKey(cycle[index]))
                            .bold()
                            .font(.system(size: 15))
                            .foregroundStyle(todo.repeatTime == index ? .white : Color.myBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(todo.repeatTime == index ? themeColor : Color.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(todo.repeatTime == index ? themeColor : Color.gray.opacity(0.3), lineWidth: 1.5)
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // 改进的时间选择器 - 使用滚轮选择器
    private var improvedDurationPicker: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStringKey("所需时间"))
                .bold()
                .foregroundStyle(Color.myBlack)
                .padding(.horizontal)
            
            // 快捷时间选项
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    quickTimeButton(label: "30分钟", days: 0, hours: 0, minutes: 30)
                    quickTimeButton(label: "1小时", days: 0, hours: 1, minutes: 0)
                    quickTimeButton(label: "2小时", days: 0, hours: 2, minutes: 0)
                    quickTimeButton(label: "半天", days: 0, hours: 4, minutes: 0)
                    quickTimeButton(label: "1天", days: 1, hours: 0, minutes: 0)
                    quickTimeButton(label: "3天", days: 3, hours: 0, minutes: 0)
                    quickTimeButton(label: "1周", days: 7, hours: 0, minutes: 0)
                }
                .padding(.horizontal)
            }
            
            // 自定义时间输入 - 使用滚轮选择器
            HStack(spacing: 0) {
                pickerColumn(title: "天", selection: $todo.Day, range: 0...31)
                pickerColumn(title: "时", selection: $todo.Hour, range: 0...23)
                pickerColumn(title: "分", selection: $todo.Min, range: 0...59)
            }
            .frame(height: 150)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
            )
            .padding(.horizontal)
        }
    }
    
    // 滚轮选择器列
    private func pickerColumn(title: String, selection: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(spacing: 0) {
            Text(LocalizedStringKey(title))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.blackGray)
                .padding(.bottom, 8)
            
            Picker("", selection: selection) {
                ForEach(range, id: \.self) { value in
                    Text("\(value)")
                        .font(.system(size: 20, weight: .medium))
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
        }
    }
    
    private func quickTimeButton(label: String, days: Int, hours: Int, minutes: Int) -> some View {
        Button {
            todo.Day = days
            todo.Hour = hours
            todo.Min = minutes
        } label: {
            Text(LocalizedStringKey(label))
                .bold()
                .font(.system(size: 15))
                .foregroundStyle(
                    (todo.Day == days && todo.Hour == hours && todo.Min == minutes) 
                    ? .white : Color.myBlack
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            (todo.Day == days && todo.Hour == hours && todo.Min == minutes)
                            ? themeColor : Color.white
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            (todo.Day == days && todo.Hour == hours && todo.Min == minutes)
                            ? themeColor : Color.gray.opacity(0.3), 
                            lineWidth: 1.5
                        )
                )
        }
    }
    

    
    // MARK: - Bottom Buttons
    
    private var bottomButtons: some View {
        HStack {
            Button { cancel() } label: {
                buttonLabel(text: "取消", color: Color.creamPink)
            }
            .frame(maxWidth: .infinity)
            
            Button { confirm() } label: {
                buttonLabel(text: "确定", color: themeColor)
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
