//
//  SearchTodoView.swift
//  DeadLineTodo
//
//  Search tasks view
//

import SwiftUI
import SwiftData
import WidgetKit

struct SearchTodoView: View {
    
    @Query private var todoData: [TodoData]
    @Environment(\.modelContext) private var modelContext
    
    @Binding var addTodoIsPresent: Bool
    @Binding var emergencyNum: Int
    
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText = ""
    @State private var editTodoIsPresent = false
    @State private var isShowingDatePicker = false
    @State private var selectedDate = Date()
    @State private var allowToTap = false
    @State private var isAddDateAlertPresent = false
    
    private let notificationService = NotificationService.shared
    private let reminderService = ReminderService.shared
    private let calendarService = CalendarService.shared
    private let todoService = TodoService.shared
    
    init(sort: SortDescriptor<TodoData>, addTodoIsPresent: Binding<Bool>, emergencyNum: Binding<Int>) {
        _todoData = Query(sort: [sort])
        _addTodoIsPresent = addTodoIsPresent
        _emergencyNum = emergencyNum
    }
    
    private var filteredTodos: [TodoData] {
        guard !searchText.isEmpty else { return [] }
        return todoData.filter { $0.content.lowercased().contains(searchText.lowercased()) }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("搜索")
                    .font(.system(size: 30))
                    .bold()
                    .padding(20)
                    .foregroundStyle(Color.myBlack)
                Spacer()
            }
            
            HStack {
                TextField("搜索任务", text: $searchText)
                    .bold()
                    .foregroundStyle(Color.myBlack)
                    .padding(.horizontal, 20)
                    .padding(.bottom)
            }
            
            ScrollView {
                LazyVStack {
                    ForEach(filteredTodos, id: \.id) { todo in
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
                let maxOffset: CGFloat = todo.done ? 65 : 160
                actionButtons(for: todo)
                    .offset(x: min(0, todo.offset + maxOffset))
                    .opacity(Double(-todo.offset) / maxOffset)
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
    }
    
    private func actionButtons(for todo: TodoData) -> some View {
        HStack {
            Spacer()
            Button { deleteTodo(todo) } label: { actionIcon("trash", .red) }
            
            if !todo.done {
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
                let targetOffset: CGFloat = todo.done ? -65 : -160
                
                if todo.offset <= -70 {
                    withAnimation(.smooth(duration: 0.4)) {
                        todo.offset = targetOffset
                        todo.lastoffset = targetOffset
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
        guard allowToTap else { return }
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

extension SearchTodoView {
    @MainActor final class SearchViewModel: ObservableObject {
        @Published var selectedTodoId: UUID?
    }
}
