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
        VStack(spacing: 16) {
            // 优先级
            prioritySelector
            
            // 重复周期
            cycleSelector
            
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
            improvedDurationPicker
        }
    }

    // MARK: - Form Components
    
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
                                    .fill(selectedPriority == index ? Color.blackBlue2 : Color.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedPriority == index ? Color.blackBlue2 : Color.gray.opacity(0.3), lineWidth: 1.5)
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
                        selectedCycle = index
                    } label: {
                        Text(LocalizedStringKey(cycle[index]))
                            .bold()
                            .font(.system(size: 15))
                            .foregroundStyle(selectedCycle == index ? .white : Color.myBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedCycle == index ? Color.blackBlue2 : Color.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedCycle == index ? Color.blackBlue2 : Color.gray.opacity(0.3), lineWidth: 1.5)
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
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
                pickerColumn(title: "天", selection: $selectedDays, range: 0...31)
                pickerColumn(title: "时", selection: $selectedHours, range: 0...23)
                pickerColumn(title: "分", selection: $selectedMinutes, range: 0...59)
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
            selectedDays = days
            selectedHours = hours
            selectedMinutes = minutes
        } label: {
            Text(LocalizedStringKey(label))
                .bold()
                .font(.system(size: 15))
                .foregroundStyle(
                    (selectedDays == days && selectedHours == hours && selectedMinutes == minutes) 
                    ? .white : Color.myBlack
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            (selectedDays == days && selectedHours == hours && selectedMinutes == minutes)
                            ? Color.blackBlue2 : Color.white
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            (selectedDays == days && selectedHours == hours && selectedMinutes == minutes)
                            ? Color.blackBlue2 : Color.gray.opacity(0.3), 
                            lineWidth: 1.5
                        )
                )
        }
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
