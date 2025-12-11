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
    
    private func filterTodo(_ todo: TodoData) -> Bool {
        !searchText.isEmpty && todo.content.lowercased().contains(searchText.lowercased())
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
                    ForEach(todoData.indices, id: \.self) { index in
                        if filterTodo(todoData[index]) {
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
            }
        }
        .sheet(isPresented: $isShowingDatePicker) { datePickerSheet }
        .alert("提醒", isPresented: $isAddDateAlertPresent) {
            Button("确定") { isAddDateAlertPresent = false }
        } message: { Text("任务尚未开始") }
    }

    private func todoRow(at index: Int) -> some View {
        ZStack {
            HStack {
                Spacer()
                let maxOffset: CGFloat = todoData[index].done ? 65 : 160
                actionButtons(at: index)
                    .offset(x: min(0, todoData[index].offset + maxOffset))
                    .opacity(Double(-todoData[index].offset) / maxOffset)
            }
            
            Button(action: {
                viewModel.selectedIndex = index
                editTodoIsPresent = true
            }) {
                TodoCardView(todo: todoData[index], rowWidth: .zero, onTap: {})
                    .opacity(0)
                    .overlay(
                        GeometryReader { geo in
                            TodoCardView(todo: todoData[index], rowWidth: geo.size.width, onTap: {})
                        }
                    )
                    .simultaneousGesture(swipeGesture(at: index))
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .offset(x: todoData[index].offset)
        }
        .padding(.top)
    }
    
    private func actionButtons(at index: Int) -> some View {
        HStack {
            Spacer()
            Button { deleteTodo(at: index) } label: { actionIcon("trash", .red) }
            
            if !todoData[index].done {
                Button { toggleDoing(at: index) } label: {
                    actionIcon(todoData[index].doing ? "pause.circle" : "restart.circle", Color.blackBlue2)
                }
                Button { completeTodo(at: index) } label: { actionIcon("checkmark.circle", Color.blackBlue2) }
                    .contextMenu {
                        Button { isShowingDatePicker = true; viewModel.selectedIndex = index } label: {
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
    
    private func swipeGesture(at index: Int) -> some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { gesture in
                if gesture.translation.width < 0 || todoData[index].lastoffset != 0 {
                    allowToTap = false
                    withAnimation(.linear(duration: 0.05)) {
                        todoData[index].offset = todoData[index].lastoffset + gesture.translation.width
                    }
                }
            }
            .onEnded { gesture in
                if todoData.indices.contains(index) {
                    let targetOffset: CGFloat = todoData[index].done ? -65 : -160
                    
                    if todoData[index].offset <= -70 {
                        withAnimation(.smooth(duration: 0.4)) {
                            if todoData.indices.contains(index) {
                                todoData[index].offset = targetOffset
                                todoData[index].lastoffset = targetOffset
                            }
                            allowToTap = true
                        }
                    } else {
                        withAnimation(.smooth(duration: 0.4)) {
                            todoData[index].offset = 0
                            todoData[index].lastoffset = 0
                        }
                    }
                }
            }
    }
    
    private var datePickerSheet: some View {
        VStack {
            DatePicker("选择完成时间", selection: $selectedDate).datePickerStyle(.graphical).padding()
            Button("确定") {
                if todoData.indices.contains(viewModel.selectedIndex) {
                    completeTodo(at: viewModel.selectedIndex, doneDate: selectedDate)
                }
                isShowingDatePicker = false
            }.padding()
        }
    }
    
    private func deleteTodo(at index: Int) {
        guard todoData.indices.contains(index), allowToTap else { return }
        let todo = todoData[index]
        if todo.emergency { emergencyNum -= 1 }
        notificationService.cancelAllNotifications(for: todo)
        reminderService.removeReminder(title: todo.content)
        calendarService.deleteEvent(title: todo.content)
        modelContext.delete(todo)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func toggleDoing(at index: Int) {
        guard todoData.indices.contains(index), allowToTap, todoData[index].addDate <= Date() else {
            if todoData.indices.contains(index) && todoData[index].addDate > Date() { isAddDateAlertPresent = true }
            return
        }
        withAnimation { _ = todoService.toggleDoing(todoData[index], notificationService: notificationService) }
    }
    
    private func completeTodo(at index: Int, doneDate: Date = Date()) {
        guard todoData.indices.contains(index), allowToTap else { return }
        guard todoData[index].addDate <= Date() else { isAddDateAlertPresent = true; return }
        _ = todoService.completeTodo(todoData[index], doneDate: doneDate, emergencyNum: &emergencyNum,
            modelContext: modelContext, notificationService: notificationService,
            reminderService: reminderService, calendarService: calendarService)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

extension SearchTodoView {
    @MainActor final class SearchViewModel: ObservableObject {
        @Published var selectedIndex = 0
    }
}
