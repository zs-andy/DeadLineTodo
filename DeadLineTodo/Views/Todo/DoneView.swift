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
                    ForEach(todoData.indices, id: \.self) { index in
                        if todoData[index].done {
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
    }

    private func todoRow(at index: Int) -> some View {
        ZStack {
            HStack {
                Spacer()
                Button {
                    guard allowToTap else { return }
                    if todoData.indices.contains(index) {
                        modelContext.delete(todoData[index])
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                } label: {
                    ZStack {
                        Circle().foregroundStyle(.thinMaterial).frame(width: 40, height: 40)
                        Image(systemName: "trash").padding(5).bold().font(.system(size: 20)).foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 5)
                .offset(x: min(0, todoData[index].offset + 65))
                .opacity(Double(-todoData[index].offset) / 65.0)
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
                    if todoData[index].offset <= -45 {
                        withAnimation(.smooth(duration: 0.4)) {
                            if todoData.indices.contains(index) {
                                todoData[index].offset = -65
                                todoData[index].lastoffset = -65
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
}

extension DoneView {
    @MainActor final class DoneViewModel: ObservableObject {
        @Published var selectedIndex = 0
    }
}
