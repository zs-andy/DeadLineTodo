//
//  TodoListView.swift
//  DeadLineTodo
//
//  Main todo list view
//

import SwiftUI
import SwiftData
import WidgetKit
import TipKit
import SwiftUIPullToRefresh

struct TodoListView: View {
    
    // MARK: - Properties
    
    @Query private var todoData: [TodoData]
    @Query private var userSettings: [UserSetting]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var store: StoreKitManager
    
    @Binding var addTodoIsPresent: Bool
    @Binding var emergencyNum: Int
    
    @StateObject private var viewModel = TodoListViewModel()
    @State private var editTodoIsPresent = false
    @State private var rowWidth: CGFloat?
    @State private var isShowingDatePicker = false
    @State private var selectedDate = Date()
    @State private var allowToTap = false
    @State private var isAddDateAlertPresent = false
    @State private var isRefreshing = false
    
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    private let notificationService = NotificationService.shared
    private let reminderService = ReminderService.shared
    private let calendarService = CalendarService.shared
    private let todoService = TodoService.shared
    
    private let addFirstTaskTip = FirstTaskTip()
    private let addTaskTip = AddContentTip()
    
    init(sort: SortDescriptor<TodoData>, addTodoIsPresent: Binding<Bool>, emergencyNum: Binding<Int>) {
        _todoData = Query(filter: #Predicate { $0.todo == true || $0.emergency == true }, sort: [sort])
        _addTodoIsPresent = addTodoIsPresent
        _emergencyNum = emergencyNum
    }

    // MARK: - Body
    
    var body: some View {
        VStack {
            // 标题
            HStack {
                Text("待办")
                    .font(.system(size: 30))
                    .bold()
                    .padding(20)
                    .foregroundStyle(Color.myBlack)
                Spacer()
            }
            
            // 列表
            RefreshableScrollView(
                loadingViewBackgroundColor: Color.grayWhite1,
                threshold: 80
            ) { done in
                isRefreshing = true
                // 使用低优先级队列同步数据，避免阻塞 UI
                DispatchQueue.global(qos: .utility).async {
                    DispatchQueue.main.async {
                        syncData()
                        // 添加触觉反馈
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        
                        // 延迟一点让用户看到刷新完成
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isRefreshing = false
                            done()
                        }
                    }
                }
            } content: {
                LazyVStack {
                    TipView(addFirstTaskTip).padding(.horizontal)
                    TipView(addTaskTip).padding(.horizontal)
                    
                    ForEach(todoData.indices, id: \.self) { index in
                        if todoData.indices.contains(index) {
                            todoRow(at: index)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 150)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .fullScreenCover(isPresented: $editTodoIsPresent) {
            if todoData.indices.contains(viewModel.selectedIndex) {
                EditTodoView(isPresented: $editTodoIsPresent, todo: todoData[viewModel.selectedIndex])
            } else {
                Text("无效的待办事项")
            }
        }
        .sheet(isPresented: $isShowingDatePicker) {
            datePickerSheet
        }
        .alert("提醒", isPresented: $isAddDateAlertPresent) {
            Button("确定") { isAddDateAlertPresent = false }
        } message: {
            Text("任务尚未开始")
        }
    }
    
    // MARK: - Todo Row
    
    private func todoRow(at index: Int) -> some View {
        ZStack {
            // 滑动操作按钮
            HStack {
                Spacer()
                actionButtons(at: index)
                    .offset(x: -2)
            }
            
            // 卡片
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.grayWhite2)
                
                TodoCardView(
                    todo: todoData[index],
                    rowWidth: rowWidth ?? 0,
                    onTap: {
                        // 只有在没有滑动时才允许点击
                        guard todoData[index].offset == 0 && !viewModel.isDragging else { return }
                        viewModel.selectedIndex = index
                        editTodoIsPresent = true
                    }
                )
                .simultaneousGesture(swipeGesture(at: index))
            }
            .background(GeometryReader { geo in
                Color.clear.onAppear { rowWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, newValue in rowWidth = newValue }
            })
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .offset(x: todoData[index].offset)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: todoData[index].offset)
        }
        .padding(.top)
    }

    // MARK: - Action Buttons
    
    private func actionButtons(at index: Int) -> some View {
        HStack {
            Spacer()
            
            // 删除按钮
            Button {
                deleteTodo(at: index)
            } label: {
                actionButtonIcon(systemName: "trash", color: .red)
            }
            
            // 开始/暂停按钮
            Button {
                toggleDoing(at: index)
            } label: {
                actionButtonIcon(
                    systemName: todoData[index].doing ? "pause.circle" : "restart.circle",
                    color: Color.blackBlue2
                )
            }
            
            // 完成按钮
            Button {
                completeTodo(at: index)
            } label: {
                actionButtonIcon(systemName: "checkmark.circle", color: Color.blackBlue2)
            }
            .contextMenu {
                Button {
                    isShowingDatePicker = true
                    viewModel.selectedIndex = index
                } label: {
                    Label("选择日期和时间", systemImage: "calendar")
                }
            }
        }
        .padding(.horizontal, 5)
    }
    
    private func actionButtonIcon(systemName: String, color: Color) -> some View {
        ZStack {
            Circle()
                .foregroundStyle(.thinMaterial)
                .frame(width: 40, height: 40)
            Image(systemName: systemName)
                .padding(5)
                .bold()
                .font(.system(size: 20))
                .foregroundStyle(color)
        }
    }
    
    // MARK: - Swipe Gesture
    
    private func swipeGesture(at index: Int) -> some Gesture {
        DragGesture()
            .onChanged { gesture in
                guard gesture.translation.width < 0 || todoData[index].lastoffset != 0 else { return }
                
                // 标记正在拖动
                viewModel.isDragging = true
                allowToTap = false
                
                // 计算新的偏移量，添加阻尼效果
                let translation = gesture.translation.width
                let newOffset = todoData[index].lastoffset + translation
                
                // 限制最大滑动距离，添加阻尼
                let maxOffset: CGFloat = -155
                if newOffset < maxOffset {
                    let excess = maxOffset - newOffset
                    todoData[index].offset = maxOffset - excess * 0.3
                } else if newOffset > 0 {
                    todoData[index].offset = newOffset * 0.3
                } else {
                    todoData[index].offset = newOffset
                }
            }
            .onEnded { gesture in
                guard todoData.indices.contains(index) else { return }
                
                let velocity = gesture.predictedEndTranslation.width - gesture.translation.width
                let threshold: CGFloat = 60  // 增加阈值，减少误触
                
                // 根据滑动距离和速度判断
                if todoData[index].offset <= -threshold || velocity < -150 {
                    todoData[index].offset = -155
                    todoData[index].lastoffset = -155
                    allowToTap = true
                    
                    // 添加触觉反馈
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                } else {
                    todoData[index].offset = 0
                    todoData[index].lastoffset = 0
                }
                
                // 延迟重置拖动状态，防止误触
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    viewModel.isDragging = false
                }
                
                editTodoIsPresent = false
            }
    }
    
    // MARK: - Date Picker Sheet
    
    private var datePickerSheet: some View {
        VStack {
            DatePicker("选择完成时间", selection: $selectedDate)
                .datePickerStyle(.graphical)
                .padding()
            
            Button("确定") {
                if todoData.indices.contains(viewModel.selectedIndex) {
                    completeTodo(at: viewModel.selectedIndex, doneDate: selectedDate)
                }
                isShowingDatePicker = false
            }
            .padding()
        }
    }

    // MARK: - Actions
    
    private func deleteTodo(at index: Int) {
        guard todoData.indices.contains(index), allowToTap else { return }
        
        let todo = todoData[index]
        notificationService.cancelAllNotifications(for: todo)
        reminderService.removeReminder(title: todo.content)
        calendarService.deleteEvent(title: todo.content)
        
        if todo.emergency { emergencyNum -= 1 }
        modelContext.delete(todo)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func toggleDoing(at index: Int) {
        guard todoData.indices.contains(index), allowToTap else { return }
        
        let todo = todoData[index]
        guard todo.addDate <= Date() else {
            isAddDateAlertPresent = true
            return
        }
        
        withAnimation {
            _ = todoService.toggleDoing(todo, notificationService: notificationService)
        }
    }
    
    private func completeTodo(at index: Int, doneDate: Date = Date()) {
        guard todoData.indices.contains(index), allowToTap else { return }
        
        let todo = todoData[index]
        guard todo.addDate <= Date() else {
            isAddDateAlertPresent = true
            return
        }
        
        withAnimation {
            _ = todoService.completeTodo(
                todo,
                doneDate: doneDate,
                emergencyNum: &emergencyNum,
                modelContext: modelContext,
                notificationService: notificationService,
                reminderService: reminderService,
                calendarService: calendarService
            )
        }
    }
    
    private func syncData() {
        guard !userSettings.isEmpty else { return }
        
        if userSettings[0].reminder {
            // 同步提醒事项
            let newTodos = reminderService.syncReminders(existingTodos: todoData)
            newTodos.forEach { modelContext.insert($0) }
        }
        
        if userSettings[0].calendar {
            // 同步日历事件
            let newTodos = calendarService.syncEvents(
                selectedCalendars: userSettings[0].selectedOptions,
                existingTodos: todoData,
                modelContext: modelContext
            )
            newTodos.forEach { modelContext.insert($0) }
        }
    }
}

// MARK: - ViewModel

extension TodoListView {
    @MainActor
    final class TodoListViewModel: ObservableObject {
        @Published var selectedIndex = 0
        @Published var isDragging = false
    }
}
