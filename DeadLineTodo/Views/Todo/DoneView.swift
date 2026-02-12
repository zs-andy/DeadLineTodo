//
//  DoneView.swift
//  DeadLineTodo
//
//  Completed tasks view
//

import SwiftUI
import SwiftData
import WidgetKit

struct DoneView: View {
    
    @Query(sort: \TodoData.doneDate, order: .reverse) private var todoData: [TodoData]
    @Environment(\.modelContext) private var modelContext
    
    @Binding var addTodoIsPresent: Bool
    
    @StateObject private var viewModel = DoneViewModel()
    @State private var editTodoIsPresent = false
    @State private var allowToTap = false
    
    /// Filtered list of completed todos
    private var doneTodos: [TodoData] {
        todoData.filter { $0.done }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("已完成")
                    .font(.system(size: 30))
                    .bold()
                    .padding(20)
                    .foregroundStyle(Color.myBlack)
                Spacer()
            }
            
            ScrollView {
                LazyVStack {
                    ForEach(doneTodos, id: \.id) { todo in
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
    }

    private func todoRow(for todo: TodoData) -> some View {
        ZStack {
            HStack {
                Spacer()
                Button {
                    guard allowToTap else { return }
                    modelContext.delete(todo)
                    WidgetCenter.shared.reloadAllTimelines()
                } label: {
                    ZStack {
                        Circle().foregroundStyle(.thinMaterial).frame(width: 40, height: 40)
                        Image(systemName: "trash").padding(5).bold().font(.system(size: 20)).foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 5)
                .offset(x: min(0, todo.offset + 65))
                .opacity(Double(-todo.offset) / 65.0)
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
                if todo.offset <= -45 {
                    withAnimation(.smooth(duration: 0.4)) {
                        todo.offset = -65
                        todo.lastoffset = -65
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
}

extension DoneView {
    @MainActor final class DoneViewModel: ObservableObject {
        @Published var selectedTodoId: UUID?
    }
}
