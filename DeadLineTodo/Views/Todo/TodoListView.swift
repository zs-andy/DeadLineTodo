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
                    
                    ForEach(todoData, id: \.id) { todo in
                        todoRow(for: todo)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 150)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .fullScreenCover(isPresented: $editTodoIsPresent) {
            if let selectedTodo = todoData.first(where: { $0.id == viewModel.selectedTodoId }) {
                EditTodoView(isPresented: $editTodoIsPresent, todo: selectedTodo)
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
    
    private func todoRow(for todo: TodoData) -> some View {
        ZStack {
            // 滑动操作按钮
            HStack {
                Spacer()
                actionButtons(for: todo)
                    .offset(x: min(0, todo.offset + 160))
                    .opacity(Double(-todo.offset) / 160.0)
            }
            
            // 卡片
            Button(action: {
                viewModel.selectedTodoId = todo.id
                editTodoIsPresent = true
            }) {
                TodoCardView(todo: todo, rowWidth: .zero, onTap: {})
                    .opacity(0)
                    .overlay(
                        GeometryReader { geo in
                            TodoCardView(
                                todo: todo,
                                rowWidth: geo.size.width,
                                onTap: {}
                            )
                        }
                    )
                    .simultaneousGesture(swipeGesture(for: todo))
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .offset(x: todo.offset)
        }
        .padding(.top)
        .id(todo.id) // 使用稳定的 ID
    }

    // MARK: - Action Buttons
    
    private func actionButtons(for todo: TodoData) -> some View {
        HStack {
            Spacer()
            
            // 删除按钮
            Button {
                deleteTodo(todo)
            } label: {
                actionButtonIcon(systemName: "trash", color: .red)
            }
            
            // 开始/暂停按钮
            Button {
                toggleDoing(todo)
            } label: {
                actionButtonIcon(
                    systemName: todo.doing ? "pause.circle" : "restart.circle",
                    color: Color.blackBlue2
                )
            }
            
            // 完成按钮
            Button {
                completeTodo(todo)
            } label: {
                actionButtonIcon(systemName: "checkmark.circle", color: Color.blackBlue2)
            }
            .contextMenu {
                Button {
                    isShowingDatePicker = true
                    viewModel.selectedTodoId = todo.id
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
    
    private func swipeGesture(for todo: TodoData) -> some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { gesture in
                if gesture.translation.width < 0 || todo.lastoffset != 0 {
                    allowToTap = false
                    withAnimation(.linear(duration: 0.05)) {
                        todo.offset = todo.lastoffset + gesture.translation.width
                    }
                }
            }
            .onEnded { gesture in
                if todo.offset <= -70 {
                    withAnimation(.smooth(duration: 0.4)) {
                        todo.offset = -160
                        todo.lastoffset = -160
                        allowToTap = true
                    }
                } else {
                    withAnimation(.smooth(duration: 0.4)) {
                        todo.offset = 0
                        todo.lastoffset = 0
                    }
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
                if let todo = todoData.first(where: { $0.id == viewModel.selectedTodoId }) {
                    completeTodo(todo, doneDate: selectedDate)
                }
                isShowingDatePicker = false
            }
            .padding()
        }
    }

    // MARK: - Actions
    
    private func deleteTodo(_ todo: TodoData) {
        guard allowToTap else { return }
        
        notificationService.cancelAllNotifications(for: todo)
        reminderService.removeReminder(todoId: todo.id, title: todo.content)
        calendarService.deleteEvent(todoId: todo.id, title: todo.content)
        
        if todo.emergency { emergencyNum -= 1 }
        modelContext.delete(todo)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func toggleDoing(_ todo: TodoData) {
        guard allowToTap else { return }
        
        guard todo.addDate <= Date() else {
            isAddDateAlertPresent = true
            return
        }
        
        withAnimation {
            _ = todoService.toggleDoing(todo, notificationService: notificationService)
        }
    }
    
    private func completeTodo(_ todo: TodoData, doneDate: Date = Date()) {
        guard allowToTap else { return }
        
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
            // 从外部提醒事项同步修改到App
            reminderService.syncExternalChanges(existingTodos: todoData) {}
        }
        
        if userSettings[0].calendar {
            // 从外部日历同步修改到App
            calendarService.syncExternalChanges(existingTodos: todoData)
        }
    }
}

// MARK: - ViewModel

extension TodoListView {
    @MainActor
    final class TodoListViewModel: ObservableObject {
        @Published var selectedTodoId: UUID?
    }
}
