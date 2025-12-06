//
//  TodoCardView.swift
//  DeadLineTodo
//
//  Reusable todo card component
//

import SwiftUI

struct TodoCardView: View {
    
    let todo: TodoData
    let rowWidth: CGFloat
    let onTap: () -> Void
    
    private let todoService = TodoService.shared
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                // 背景和进度条
                progressBackground
                
                // 紧急线
                emergencyLine
                
                // 内容
                cardContent
                
                // 滑动提示图标
                swipeHintIcon
            }
        }
        .buttonStyle(CardButtonStyle())
    }
    
    // 滑动提示图标
    private var swipeHintIcon: some View {
        HStack {
            Spacer()
            VStack {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.blackGray.opacity(0.3))
                    .padding(.trailing, 16)
                    .padding(.top, 16)
                Spacer()
            }
        }
    }
    
    // MARK: - Progress Background
    
    @ViewBuilder
    private var progressBackground: some View {
        let progressWidth = todoService.getProgressWidth(for: todo, totalWidth: rowWidth)
        
        if progressWidth < rowWidth {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.grayWhite2)
            Rectangle()
                .fill(Color.creamPink)
                .frame(width: max(0, progressWidth))
        } else {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.creamPink)
        }
    }
    
    // MARK: - Emergency Line
    
    private var emergencyLine: some View {
        Rectangle()
            .fill(Color.creamBlue)
            .offset(x: todoService.getEmergencyLinePosition(for: todo, totalWidth: rowWidth))
            .frame(width: 2)
    }

    // MARK: - Card Content
    
    private var cardContent: some View {
        VStack {
            HStack {
                // 左侧：标题和截止日期
                VStack(alignment: .leading) {
                    titleText
                    repeatTimesText
                    
                    Text("截止日期")
                        .textTitleStyle()
                    Text("\(todo.endDate.localizedDateString) \(todo.endDate.timeString)")
                        .foregroundStyle(Color.blackGray)
                        .bold()
                        .font(.system(size: 12))
                }
                
                Spacer()
                
                // 右侧：剩余时间或状态
                VStack(alignment: .trailing) {
                    if todo.done {
                        doneStatusView
                    } else {
                        activeStatusView
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Title
    
    private var titleText: some View {
        let suffix = prioritySuffix
        return Text("\(todo.content)\(suffix)")
            .textContentStyle()
            .padding(.bottom, todo.repeatTime == 0 ? 8 : 0)
    }
    
    private var prioritySuffix: String {
        switch todo.priority {
        case 1: return "!!!"
        case 5: return "!!"
        case 9: return "!"
        default: return ""
        }
    }
    
    // MARK: - Repeat Times
    
    @ViewBuilder
    private var repeatTimesText: some View {
        if todo.repeatTime > 0 {
            let unit = ["天", "周", "月"][todo.repeatTime - 1]
            Text("已坚持\(todo.times)\(unit)")
                .textRepeatedTimesStyle()
        }
    }
    
    // MARK: - Done Status
    
    private var doneStatusView: some View {
        VStack(alignment: .trailing) {
            Text("实际完成时长")
                .textTitleStyle()
            actualFinishTimeText
            
            Spacer()
            
            Text("完成时间")
                .textTitleStyle()
            completionStatusText
        }
    }
    
    private var actualFinishTimeText: some View {
        let decomposed = todo.actualFinishTime.decomposed
        return HStack {
            if decomposed.days > 0 {
                Text("\(decomposed.days)天").textTimeStyle()
            }
            if decomposed.hours > 0 {
                Text("\(decomposed.hours)时").textTimeStyle()
            }
            if decomposed.minutes > 0 {
                Text("\(decomposed.minutes)分").textTimeStyle()
            }
        }
    }
    
    @ViewBuilder
    private var completionStatusText: some View {
        let needTime = TimeInterval.from(days: todo.Day, hours: todo.Hour, minutes: todo.Min)
        let timeLeft = todo.endDate.timeIntervalSince1970 - todo.doneDate.timeIntervalSince1970
        
        if timeLeft - needTime > 0 {
            Text("\(todo.doneDate.localizedDateStringWithoutYear) \(todo.doneDate.timeString)")
                .textTimeStyle()
        } else if timeLeft <= 0 {
            Text("已截止").textEndDateStyle()
        } else {
            Text("将截止").textEndDateStyle()
        }
    }
    
    // MARK: - Active Status
    
    private var activeStatusView: some View {
        VStack(alignment: .trailing) {
            Text("剩余所需时间")
                .textTitleStyle()
            remainingTimeText
            
            Spacer()
            
            if todo.doing {
                Text("正在进行")
                    .textTitleStyle()
                Text("剩余\(formattedLeftTime)")
                    .textTimeStyle()
            } else {
                Text("剩余时间")
                    .textTitleStyle()
                leftTimeStatusText
            }
        }
    }
    
    private var remainingTimeText: some View {
        HStack {
            if todo.Day > 0 {
                Text("\(todo.Day)天").textTimeStyle()
            }
            if todo.Hour > 0 {
                Text("\(todo.Hour)时").textTimeStyle()
            }
            if todo.Min > 0 {
                Text("\(todo.Min)分").textTimeStyle()
            }
        }
    }
    
    @ViewBuilder
    private var leftTimeStatusText: some View {
        let leftTime = todoService.getLeftTime(for: todo)
        let decomposed = leftTime.decomposed
        
        if leftTime <= 0 {
            Text("已截止").textEndDateStyle()
        } else if leftTime <= 60 {
            Text("将截止").textEndDateStyle()
        } else {
            HStack {
                if decomposed.days > 0 {
                    Text("\(decomposed.days)天").textTimeStyle()
                }
                if decomposed.hours > 0 {
                    Text("\(decomposed.hours)时").textTimeStyle()
                }
                if decomposed.minutes > 0 {
                    Text("\(decomposed.minutes)分").textTimeStyle()
                }
            }
        }
    }
    
    private var formattedLeftTime: String {
        let leftTime = todoService.getLeftTime(for: todo)
        let decomposed = leftTime.decomposed
        var parts: [String] = []
        if decomposed.days > 0 { parts.append("\(decomposed.days)天") }
        if decomposed.hours > 0 { parts.append("\(decomposed.hours)时") }
        if decomposed.minutes > 0 { parts.append("\(decomposed.minutes)分") }
        return parts.joined()
    }
}

// MARK: - Custom Button Style

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
