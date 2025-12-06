//
//  AddTodoView.swift
//  DeadLineTodo
//
//  Add new todo view
//

import SwiftUI
import SwiftData
import WidgetKit
import TipKit

struct AddTodoView: View {
    
    // MARK: - Properties
    
    @Binding var isPresented: Bool
    @Binding var isActionInProgress: Bool
    @Environment(\.modelContext) private var modelContext
    @Query private var todoData: [TodoData]
    @Query private var userSettings: [UserSetting]
    @EnvironmentObject private var store: StoreKitManager
    
    @State var todo: TodoData
    @State private var selectedHours = 2
    @State private var selectedMinutes = 0
    @State private var selectedDays = 0
    @State private var selectedPriority = 0
    @State private var selectedCycle = 0
    @State private var calendarId = 0
    @State private var calendar2Id = 0
    
    @State private var showAlert = false
    @State private var alertType: AlertType = .none
    @State private var isStorePresent = false
    @State private var emergencyTime = Date()
    
    private let priority = ["无", "高", "中", "低"]
    private let cycle = ["无", "天", "周", "月"]
    
    private let notificationService = NotificationService.shared
    private let reminderService = ReminderService.shared
    private let calendarService = CalendarService.shared
    
    private let setStartTimeTip = SetStartTimeTip()
    private let setDeadlineTip = SetDeadlineTip()
    private let setDurationTip = SetDurationTip()
    
    enum AlertType { case none, endTime, emergencyTime, needTime, purchase }

    // MARK: - Body
    
    var body: some View {
        ZStack {
            VStack {
                // 头部
                headerView
                
                // 表单
                ScrollView(showsIndicators: false) {
                    formContent
                }
                
                Spacer()
                
                // 底部按钮
                bottomButtons
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.grayWhite1)
        .fullScreenCover(isPresented: $isStorePresent) {
            StoreView(isPresented: $isStorePresent)
        }
        .alert(Text("提醒"), isPresented: $showAlert) {
            Button("确定") {
                if alertType == .purchase { isStorePresent = true }
                alertType = .none
            }
        } message: {
            switch alertType {
            case .endTime: Text("截止时间在过去")
            case .emergencyTime: Text("开始时间不在允许范围内")
            case .needTime: Text("任务所需时间超过截止时间")
            case .purchase: Text("购买高级功能解锁重复任务功能")
            case .none: Text("")
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack {
            HStack {
                Text(LocalizedStringKey("添加任务"))
                    .bold()
                    .font(.system(size: 30))
                    .padding()
                    .foregroundStyle(Color.myBlack)
                Spacer()
            }
            
            TextField(LocalizedStringKey("输入任务内容"), text: $todo.content)
                .bold()
                .padding()
                .foregroundStyle(Color.blackBlue1)
                .font(.system(size: 25))
                .onChange(of: todo.content) { _, _ in
                    Task {
                        await SetStartTimeTip.setContentEvent.donate()
                        if #available(iOS 18.0, *) {
                            await SetStartTimeTip.setContentEvent.donate()
                        }
                    }
                }
        }
        .background(Color.creamBlue)
    }
    
    // MARK: - Form Content
    
    private var formContent: some View {
        VStack {
            // 优先级
            pickerRow(title: "任务优先级", selection: $selectedPriority, options: priority)
            
            // 重复周期
            pickerRow(title: "任务重复周期", selection: $selectedCycle, options: cycle)
            
            // 开始日期
            TipView(setStartTimeTip).padding(.horizontal)
            datePicker(title: "开始日期", selection: $todo.emergencyDate, id: calendar2Id) {
                Task {
                    await SetDeadlineTip.setStartTimeEvent.donate()
                    if #available(iOS 18.0, *) {
                        await SetDeadlineTip.setStartTimeEvent.donate()
                    }
                }
            }
            
            // 截止日期
            TipView(setDeadlineTip).padding(.horizontal)
            datePicker(title: "截止日期", selection: $todo.endDate, id: calendarId) {
                Task {
                    await SetDurationTip.setDeadlineEvent.donate()
                    if #available(iOS 18.0, *) {
                        await SetDurationTip.setDeadlineEvent.donate()
                    }
                }
            }
            
            // 所需时间
            TipView(setDurationTip).padding(.horizontal)
            durationPicker
        }
    }

    // MARK: - Form Components
    
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
    
    private func datePicker(title: String, selection: Binding<Date>, id: Int, onChange: @escaping () -> Void) -> some View {
        DatePicker(LocalizedStringKey(title), selection: selection)
            .foregroundStyle(Color.myBlack)
            .datePickerStyle(.compact)
            .padding(.horizontal)
            .bold()
            .accentColor(.blackBlue2)
            .id(id)
            .onChange(of: selection.wrappedValue) { _, _ in onChange() }
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
                durationColumn(title: "天", selection: $selectedDays, range: 0..<32)
                durationColumn(title: "时", selection: $selectedHours, range: 0..<25)
                durationColumn(title: "分", selection: $selectedMinutes, range: 0..<61)
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
    
    private func cancel() {
        calendarId += 1
        calendar2Id += 1
        invalidateTips()
        isPresented = false
    }
    
    private func confirm() {
        let needTime = TimeInterval.from(days: selectedDays, hours: selectedHours, minutes: selectedMinutes)
        let leftTime = todo.endDate.timeIntervalSince1970 - Date().timeIntervalSince1970 - needTime
        
        // 验证
        if !validate(needTime: needTime, leftTime: leftTime) { return }
        
        // 设置任务属性
        setupTodo(needTime: needTime)
        
        // 检查重复任务权限
        if selectedCycle != 0 && !store.hasPurchased {
            showAlert = true
            alertType = .purchase
            return
        }
        
        // 保存任务
        saveTodo(needTime: needTime)
    }
    
    private func validate(needTime: TimeInterval, leftTime: Double) -> Bool {
        let emergencyChanged = todo.emergencyDate != emergencyTime
        let emergencyInvalid = todo.emergencyDate > todo.endDate.addingTimeInterval(-needTime)
        
        if (emergencyInvalid && emergencyChanged) || todo.endDate < Date() || leftTime <= 0 {
            calendarId += 1
            calendar2Id += 1
            showAlert = true
            
            if emergencyInvalid && emergencyChanged {
                alertType = .emergencyTime
            } else if todo.endDate < Date() {
                alertType = .endTime
            } else {
                alertType = .needTime
            }
            return false
        }
        return true
    }
    
    private func setupTodo(needTime: TimeInterval) {
        todo.Day = selectedDays
        todo.Hour = selectedHours
        todo.Min = selectedMinutes
        todo.needTime = needTime
        todo.initialNeedTime = needTime
        todo.repeatTime = selectedCycle
        
        if todo.content.isEmpty {
            todo.content = NSLocalizedString("请输入任务内容", comment: "")
        }
        
        if emergencyTime == todo.emergencyDate {
            todo.emergencyDate = Date(timeIntervalSince1970: todo.endDate.timeIntervalSince1970 - needTime * 2)
        }
        
        // 设置优先级
        if !userSettings.isEmpty && userSettings[0].reminder {
            reminderService.addReminder(
                title: todo.content,
                priority: selectedPriority,
                dueDate: todo.emergencyDate,
                remindDate: todo.emergencyDate,
                todo: todo
            )
        } else {
            todo.priority = [0, 1, 5, 9][selectedPriority]
        }
    }
    
    private func saveTodo(needTime: TimeInterval) {
        // 发送通知
        notificationService.sendNotifications(for: todo)
        
        // 添加日历事件
        if !userSettings.isEmpty && userSettings[0].calendar {
            calendarService.addEvent(for: todo)
        }
        
        // 保存
        modelContext.insert(todo)
        try? modelContext.save()
        
        // 更新 Widget
        WidgetCenter.shared.reloadAllTimelines()
        
        // 触发提示
        Task {
            await FirstTaskTip.addFirstTaskEvent.donate()
            if #available(iOS 18.0, *) {
                await FirstTaskTip.addFirstTaskEvent.donate()
            }
        }
        
        invalidateTips()
        isPresented = false
    }
    
    private func invalidateTips() {
        setStartTimeTip.invalidate(reason: .actionPerformed)
        setDeadlineTip.invalidate(reason: .actionPerformed)
        setDurationTip.invalidate(reason: .actionPerformed)
    }
    
}
