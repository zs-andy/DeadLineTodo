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
    @State private var rowWidth: CGFloat?
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
                .offset(x: -2)
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.grayWhite2)
                TodoCardView(todo: todoData[index], rowWidth: rowWidth ?? 0) {
                    guard todoData[index].offset == 0 && !viewModel.isDragging else { return }
                    viewModel.selectedIndex = index
                    editTodoIsPresent = true
                }
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
    
    private func swipeGesture(at index: Int) -> some Gesture {
        DragGesture()
            .onChanged { gesture in
                guard gesture.translation.width < 0 || todoData[index].lastoffset != 0 else { return }
                
                viewModel.isDragging = true
                allowToTap = false
                
                let translation = gesture.translation.width
                let newOffset = todoData[index].lastoffset + translation
                
                let maxOffset: CGFloat = -65
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
                let threshold: CGFloat = 45
                
                if todoData[index].offset <= -threshold || velocity < -100 {
                    todoData[index].offset = -65
                    todoData[index].lastoffset = -65
                    allowToTap = true
                    
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                } else {
                    todoData[index].offset = 0
                    todoData[index].lastoffset = 0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.isDragging = false
                }
            }
    }
}

extension DoneView {
    @MainActor final class DoneViewModel: ObservableObject {
        @Published var selectedIndex = 0
        @Published var isDragging = false
    }
}
