//
//  DoneView.swift
//  DeadLineTodo
//
//  Created by Andy on 2024/1/27.
//

import SwiftUI
import SwiftData
import WidgetKit

extension DoneView {
    @MainActor
    class DoneViewModel: ObservableObject {
        @Published var index_: Int = 0
    }
}

struct DoneView: View {
    @Query(sort: \TodoData.doneDate, order:.reverse) var tododata: [TodoData]
    @Environment(\.modelContext) var modelContext
    @Binding var AddTodoIsPresent: Bool
    
    @StateObject private var viewModel = DoneViewModel()
    
    @State var EditTodoIsPresent: Bool = false
//    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    @State var rowWidth: CGFloat? = nil
    @State var allowToTap = false
    
    func getDateString(date: Date) -> String { //转换格式
        let dformatter = DateFormatter()
        dformatter.dateFormat = NSLocalizedString("yyyy年MM月dd日", comment: "")
        return dformatter.string(from: date)
    }
    
    func getDateStringWithoutYear(date: Date) -> String {
        let dformatter = DateFormatter()
        dformatter.dateFormat = NSLocalizedString("MM月dd日", comment: "")
        return dformatter.string(from: date)
    }
    
    func getTimeString(date: Date) -> String { //转换格式
        let dformatter = DateFormatter()
        dformatter.dateFormat = "HH:mm"
        return dformatter.string(from: date)
    }
    
    func decomposeSeconds(totalSeconds: TimeInterval) -> (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let days = Int(totalSeconds / (24 * 60 * 60))
        let remainingSeconds = totalSeconds - TimeInterval(days * 24 * 60 * 60)
        
        let hours = Int(remainingSeconds / 3600)
        let remainingSecondsAfterHours = remainingSeconds - TimeInterval(hours * 3600)
        
        let minutes = Int(remainingSecondsAfterHours / 60)
        let seconds = Int(remainingSecondsAfterHours.truncatingRemainder(dividingBy: 60))
        
        return (days, hours, minutes, seconds)
    }
    
    func getLeftTime(todo: TodoData) -> TimeInterval {
        let time = todo.Day*60*60*24 + todo.Hour*60*60 + todo.Min*60 + todo.Sec
        let leftTime = todo.endDate.timeIntervalSince1970 - Date().timeIntervalSince1970 - Double(time)
        return max(leftTime, 0)
    }
    
    func getNeedTime(todo: TodoData) -> TimeInterval {
        let time = todo.Day*60*60*24 + todo.Hour*60*60 + todo.Min*60
        return TimeInterval(time)
    }
    
    func getSize(todo: TodoData, width: Double) -> CGFloat {
        let needTime = todo.needTime - todo.actualFinishTime
        let now = Date()
        let total = todo.endDate.timeIntervalSince1970 - now.timeIntervalSince1970
        let size = (Double(needTime) / total) * width
        if size >= 0 && size <= width{
            return size
        }else{
            return width
        }
    }
    
    func location(todo: TodoData, width: Double) -> CGFloat{
        let now = Date()
        let total = todo.endDate.timeIntervalSince1970 - now.timeIntervalSince1970
        let l = ((todo.emergencyDate.timeIntervalSince1970 - now.timeIntervalSince1970) / total)*width
        return l
    }
    
    func getOffset(todo: TodoData, width: Double) -> CGFloat {
        let offset = (todo.doneDate.timeIntervalSince1970 - todo.addDate.timeIntervalSince1970) / (todo.endDate.timeIntervalSince1970 - todo.addDate.timeIntervalSince1970) * width
        return offset
    }
    
    var body: some View {
        VStack{
            HStack{
                Text("已完成")
                    .font(.system(size: 30))
                    .bold()
                    .padding(20)
                    .foregroundStyle(Color.myBlack)
                Spacer()
            }
            ScrollView{
                LazyVStack{
                    ForEach(tododata.indices, id: \.self){index in
                        if tododata[index].done {
                            ZStack{
                                HStack(){
                                    Spacer()
                                    ZStack(alignment: .trailing){
                                        HStack{
                                            Spacer()
                                            Button(action: {
                                                if tododata.indices.contains(index) {
                                                    modelContext.delete(tododata[index])
                                                }
                                                WidgetCenter.shared.reloadAllTimelines()
                                            }){
                                                ZStack{
                                                    Circle()
                                                        .foregroundStyle(.thinMaterial)
                                                        .frame(width: 40, height: 40)
                                                    Image(systemName: "trash")
                                                        .padding(5)
                                                        .bold()
                                                        .font(.system(size: 20))
                                                        .foregroundStyle(Color.red)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 5)
                                    }
                                    .offset(x: -2)
                                }
                                ZStack(){ //卡片
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(Color.grayWhite2)
                                    Button(action: {
                                        viewModel.index_ = index
                                        EditTodoIsPresent = true
                                    }){
                                        ZStack(alignment: .topLeading){
                                            if getSize(todo: tododata[index], width: rowWidth ?? 0) != rowWidth{
                                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                    .fill(Color.grayWhite2)
                                                Rectangle()
                                                    .fill(Color.creamPink)
                                                    .frame(width: getSize(todo: tododata[index], width: rowWidth ?? 0))
                                            }else{
                                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                    .fill(Color.creamPink)
                                            }
                                            Rectangle()
                                                .fill(Color.creamBlue)
                                                .offset(x: location(todo: tododata[index], width: rowWidth ?? 0))
                                                .frame(width: 2)
                                            VStack{
                                                HStack{
                                                    VStack(alignment: .leading){
                                                        if tododata[index].priority == 0{
                                                            Text("\(tododata[index].content)")
                                                                .foregroundStyle(Color.myBlack)
                                                                .multilineTextAlignment(.leading)
                                                                .padding(.bottom)
                                                                .bold()
                                                                .font(.system(size: 17))
                                                        }else if tododata[index].priority == 1 {
                                                            Text("\(tododata[index].content)!!!")
                                                                .foregroundStyle(Color.myBlack)
                                                                .multilineTextAlignment(.leading)
                                                                .padding(.bottom)
                                                                .bold()
                                                                .font(.system(size: 17))
                                                        }else if tododata[index].priority == 5 {
                                                            Text("\(tododata[index].content)!!")
                                                                .foregroundStyle(Color.myBlack)
                                                                .multilineTextAlignment(.leading)
                                                                .padding(.bottom)
                                                                .bold()
                                                                .font(.system(size: 17))
                                                        }else if tododata[index].priority == 9 {
                                                            Text("\(tododata[index].content)!")
                                                                .foregroundStyle(Color.myBlack)
                                                                .multilineTextAlignment(.leading)
                                                                .padding(.bottom)
                                                                .bold()
                                                                .font(.system(size: 17))
                                                        }
                                                        Text("截止日期")
                                                            .foregroundStyle(Color.blackGray)
                                                            .bold()
                                                            .font(.system(size: 10))
                                                        HStack{
                                                            Text("\(getDateString(date: tododata[index].endDate)) \(getTimeString(date: tododata[index].endDate))")
                                                                .foregroundStyle(Color.blackGray)
                                                                .multilineTextAlignment(.leading)
                                                                .bold()
                                                                .font(.system(size: 12))
                                                        }
                                                    }
                                                    Spacer()
                                                    VStack(alignment: .trailing){
                                                        Text("实际完成时长")
                                                            .foregroundStyle(Color.blackGray)
                                                            .bold()
                                                            .padding(.horizontal, -2)
                                                            .font(.system(size: 10))
                                                        HStack{
                                                            if decomposeSeconds(totalSeconds: tododata[index].actualFinishTime).days != 0{
                                                                Text("\(decomposeSeconds(totalSeconds: tododata[index].leftTime).days)天")
                                                                    .foregroundStyle(Color.blackGray)
                                                                    .padding(.bottom, 0.5)
                                                                    .padding(.horizontal, -3)
                                                                    .bold()
                                                                    .font(.system(size: 13))
                                                            }
                                                            if decomposeSeconds(totalSeconds: tododata[index].actualFinishTime).hours != 0 {
                                                                Text("\(decomposeSeconds(totalSeconds: tododata[index].actualFinishTime).hours)时")
                                                                    .foregroundStyle(Color.blackGray)
                                                                    .padding(.bottom, 0.5)
                                                                    .padding(.horizontal, -3)
                                                                    .bold()
                                                                    .font(.system(size: 13))
                                                            }
                                                            if decomposeSeconds(totalSeconds: tododata[index].actualFinishTime).minutes != 0{
                                                                Text("\(decomposeSeconds(totalSeconds: tododata[index].actualFinishTime).minutes)分")
                                                                    .foregroundStyle(Color.blackGray)
                                                                    .padding(.bottom, 0.5)
                                                                    .padding(.horizontal, -3)
                                                                    .bold()
                                                                    .font(.system(size: 13))
                                                            }
                                                        }
                                                        Spacer()
                                                        Text("完成时间")
                                                            .foregroundStyle(Color.blackGray)
                                                            .bold()
                                                            .padding(.horizontal, -2)
                                                            .font(.system(size: 10))
                                                        if (tododata[index].endDate.timeIntervalSince1970 - tododata[index].doneDate.timeIntervalSince1970 - getNeedTime(todo: tododata[index])) > 0{
                                                            HStack{
                                                                Text("\(getDateStringWithoutYear(date: tododata[index].doneDate)) \(getTimeString(date: tododata[index].doneDate))")
                                                                    .foregroundStyle(Color.blackGray)
                                                                    .padding(.bottom, 0.5)
                                                                    .padding(.horizontal, -3)
                                                                    .bold()
                                                                    .font(.system(size: 13))
                                                            }
                                                        }else if (tododata[index].endDate.timeIntervalSince1970 - tododata[index].doneDate.timeIntervalSince1970) <= 0 {
                                                            Text("已截止")
                                                                .foregroundStyle(Color.creamBrown)
                                                                .padding(.bottom, 0.5)
                                                                .padding(.horizontal, -3)
                                                                .bold()
                                                                .font(.system(size: 13))
                                                        }else if (tododata[index].endDate.timeIntervalSince1970 - tododata[index].doneDate.timeIntervalSince1970 - getNeedTime(todo: tododata[index])) <= 0 {
                                                            Text("将截止")
                                                                .foregroundStyle(Color.creamBrown)
                                                                .padding(.bottom, 0.5)
                                                                .padding(.horizontal, -3)
                                                                .bold()
                                                                .font(.system(size: 13))
                                                        }
                                                    }
                                                }
                                                .padding()
                                            }
                                        }
                                        .simultaneousGesture(
                                            DragGesture()
                                                .onChanged { gesture in
                                                    if gesture.translation.width < 0 || tododata[index].lastoffset != 0{
                                                        allowToTap = false
                                                        withAnimation(.linear(duration: 0.1)){
                                                            tododata[index].offset = tododata[index].lastoffset + gesture.translation.width
                                                        }
                                                    }
                                                }
                                                .onEnded { gesture in
                                                    if tododata.indices.contains(index) {
                                                        if tododata[index].offset <= -45{
                                                            withAnimation(.smooth(duration: 0.4)){
                                                                guard tododata.indices.contains(index) else { return }
                                                                tododata[index].offset = -65
                                                                tododata[index].lastoffset = -65
                                                                allowToTap = true
                                                            }
                                                        }else {
                                                            withAnimation(.smooth(duration: 0.4)){
                                                                tododata[index].offset = 0
                                                                tododata[index].lastoffset = 0
                                                            }
                                                        }
                                                        EditTodoIsPresent = false
                                                    }
                                                }
                                        )
                                    }
                                }
                                .background(GeometryReader { geometry in
                                                    Color.clear.onAppear {
                                                        // 在 onAppear 中获取控件的宽度
                                                        rowWidth = geometry.size.width
                                                    }
                                                    .onChange(of: geometry.size.width) { oldVlue, newValue in
                                                        // 当宽度发生变化时更新 rowWidth
                                                        rowWidth = newValue
                                                        print(newValue)
                                                        // 在这里可以执行刷新操作
                                                        // 例如，通过调用父视图的刷新方法来重新布局子视图
                                                    }
                                                })
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .offset(x: tododata[index].offset)
                            }
                            .padding(.top)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 150)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("编辑任务")
                        .fullScreenCover(isPresented: $EditTodoIsPresent, content: {// 模态跳转
                            if tododata.indices.contains(viewModel.index_) {
                                EditTodoView(EditTodoIsPresent: $EditTodoIsPresent, edittodo: tododata[viewModel.index_])
                            } else {
                                Text("无效的待办事项")
                            }
                        })
    }
}
