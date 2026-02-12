//
//  EmergencyView.swift
//  DeadLineTodo
//
//  Emergency tasks view
//

import SwiftUI
import SwiftData
import WidgetKit
import TipKit

struct EmergencyView: View {
    
    @Query private var todoData: [TodoData]
    @Query private var userSettings: [UserSetting]
    @Environment(\.modelContext) private var modelContext
    
    @Binding var addTodoIsPresent: Bool
    @Binding var emergencyNum: Int
    
    @StateObject private var viewModel = EmergencyViewModel()
    @State private var editTodoIsPresent = false
    @State private var isShowingDatePicker = false
    @State private var selectedDate = Date()
    @State private var allowToTap = false
    @State private var isAddDateAlertPresent = false
    
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    private let notificationService = NotificationService.shared
    private let reminderService = ReminderService.shared
    private let calendarService = CalendarService.shared
    private let todoService = TodoService.shared
    
    private let emergencyViewTip = EmergencyViewTip()
    
    /// Filtered list of emergency todos
    private var emergencyTodos: [TodoData] {
        todoData.filter { $0.emergency }
    }
    
    init(sort: SortDescriptor<TodoData>, addTodoIsPresent: Binding<Bool>, emergencyNum: Binding<Int>) {
        _todoData = Query(sort: [sort])
        _addTodoIsPresent = addTodoIsPresent
        _emergencyNum = emergencyNum
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("紧急待办")
                    .font(.system(size: 30))
                    .bold()
                    .padding(20)
                    .foregroundStyle(Color.myBlack)
                Spacer()
            }
            
            ScrollView {
                LazyVStack {
                    TipView(emergencyViewTip).padding(.horizontal)
                    
                    ForEach(emergencyTodos, id: \.id) { todo in
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
            }
        }
        .sheet(isPresented: $isShowingDatePicker) { datePickerSheet }
        .alert("提醒", isPresented: $isAddDateAlertPresent) {
            Button("确定") { isAddDateAlertPresent = false }
        } message: { Text("任务尚未开始") }
    }

    private func todoRow(for todo: TodoData) -> some View {
        ZStack {
            HStack {
                Spacer()
                actionButtons(for: todo)
                    .offset(x: min(0, todo.offset + 160))
                    .opacity(Double(-todo.offset) / 160.0)
            }
            
            Button(action: {
                viewModel.selectedTodoId = todo.id
                editTodoIsPresent = true
            }) {
                TodoCardView(todo: todo, rowWidth: .zero, onTap: {})
                    .opacity(0)
                    .overlay(
                        GeometryReader { geo in
                            TodoCardView(todo: todo, rowWidth: geo.size.width, onTap: {})
                        }
                    )
                    .simultaneousGesture(swipeGesture(for: todo))
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .offset(x: todo.offset)
        }
        .padding(.top)
        .id(todo.id)
    }
    
    private func actionButtons(for todo: TodoData) -> some View {
        HStack {
            Spacer()
            Button { deleteTodo(todo) } label: { actionIcon("trash", .red) }
            Button { toggleDoing(todo) } label: {
                actionIcon(todo.doing ? "pause.circle" : "restart.circle", Color.blackBlue2)
            }
            Button { completeTodo(todo) } label: { actionIcon("checkmark.circle", Color.blackBlue2) }
                .contextMenu {
                    Button { isShowingDatePicker = true; viewModel.selectedTodoId = todo.id } label: {
                        Label("选择日期和时间", systemImage: "calendar")
                    }
                }
        }
        .padding(.horizontal, 5)
    }
    
    private func actionIcon(_ name: String, _ color: Color) -> some View {
        ZStack {
            Circle().foregroundStyle(.thinMaterial).frame(width: 40, height: 40)
            Image(systemName: name).padding(5).bold().font(.system(size: 20)).foregroundStyle(color)
        }
    }
    
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
            }
    }
    
    private var datePickerSheet: some View {
        VStack {
            DatePicker("选择完成时间", selection: $selectedDate).datePickerStyle(.graphical).padding()
            Button("确定") {
                if let todo = todoData.first(where: { $0.id == viewModel.selectedTodoId }) {
                    completeTodo(todo, doneDate: selectedDate)
                }
                isShowingDatePicker = false
            }.padding()
        }
    }
    
    private func deleteTodo(_ todo: TodoData) {
        if todo.emergency { emergencyNum -= 1 }
        notificationService.cancelAllNotifications(for: todo)
        reminderService.removeReminder(title: todo.content)
        calendarService.deleteEvent(title: todo.content)
        modelContext.delete(todo)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func toggleDoing(_ todo: TodoData) {
        guard allowToTap, todo.addDate <= Date() else {
            if todo.addDate > Date() { isAddDateAlertPresent = true }
            return
        }
        withAnimation { _ = todoService.toggleDoing(todo, notificationService: notificationService) }
    }
    
    private func completeTodo(_ todo: TodoData, doneDate: Date = Date()) {
        guard allowToTap else { return }
        guard todo.addDate <= Date() else { isAddDateAlertPresent = true; return }
        _ = todoService.completeTodo(todo, doneDate: doneDate, emergencyNum: &emergencyNum,
            modelContext: modelContext, notificationService: notificationService,
            reminderService: reminderService, calendarService: calendarService)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

extension EmergencyView {
    @MainActor final class EmergencyViewModel: ObservableObject {
        @Published var selectedTodoId: UUID?
    }
}
