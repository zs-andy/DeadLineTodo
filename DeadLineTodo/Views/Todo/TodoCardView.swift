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
    
    // 使用计算属性替代 @State，避免横竖屏切换时的状态同步问题
    private var scaleData: (widths: [CGFloat], colors: [Bool], labels: [(position: CGFloat, text: String)]) {
        calculateScaleData(width: rowWidth)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            scaleBackground
            taskBlock
            cardContent
        }
    }
    
    private func calculateScaleData(width: CGFloat) -> (widths: [CGFloat], colors: [Bool], labels: [(position: CGFloat, text: String)]) {
        guard !todo.done, width > 0 else {
            return ([], [], [])
        }
        
        let scales = getScales()
        let totalSeconds = todo.endDate.timeIntervalSince1970 - Date().timeIntervalSince1970
        
        guard totalSeconds > 0 else {
            return ([], [], [])
        }
        
        var widths: [CGFloat] = []
        var colors: [Bool] = []
        for index in 0...scales.count {
            let startTime = index == 0 ? Date().timeIntervalSince1970 : scales[index - 1].timeIntervalSince1970
            let endTime = index == scales.count ? todo.endDate.timeIntervalSince1970 : scales[index].timeIntervalSince1970
            let w = max((endTime - startTime) / totalSeconds * width, 0)
            widths.append(w)
            colors.append(index % 2 == 0)
        }
        
        let interval = max(Int(ceil(CGFloat(scales.count) * 60 / width)), 1)
        var positions: [(CGFloat, String)] = []
        for (index, scale) in scales.enumerated() {
            if index % interval == 0 {
                let pos = (scale.timeIntervalSince1970 - Date().timeIntervalSince1970) / totalSeconds * width
                positions.append((pos - 12, scale.timeString))
            }
        }
        
        return (widths, colors, positions)
    }
    
    @ViewBuilder
    private var scaleBackground: some View {
        let data = scaleData
        
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.grayWhite2)
            
            if !data.widths.isEmpty {
                HStack(spacing: 0) {
                    ForEach(0..<data.widths.count, id: \.self) { index in
                        Rectangle()
                            .fill(data.colors[index] ? Color.grayWhite2 : Color.grayWhite1.opacity(0.5))
                            .frame(width: data.widths[index])
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .drawingGroup()
            }
            
            progressBlockView
            
            if !data.labels.isEmpty {
                ZStack(alignment: .leading) {
                    ForEach(0..<data.labels.count, id: \.self) { index in
                        Text(data.labels[index].text)
                            .font(.system(size: 7))
                            .foregroundStyle(Color.blackGray.opacity(0.4))
                            .offset(x: data.labels[index].position)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.bottom, 3)
            }
        }
    }
    
    @ViewBuilder
    private var progressBlockView: some View {
        if !todo.done && rowWidth > 0 {
            let size = getSize(width: rowWidth)
            if size != rowWidth {
                Rectangle()
                    .fill(Color.creamPink.opacity(0.85))
                    .frame(width: size)
                    .offset(x: getLocation(width: rowWidth))
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.creamPink.opacity(0.85))
            }
        }
    }
    
    private func getScales() -> [Date] {
        let now = Date()
        let end = todo.endDate
        let totalSeconds = end.timeIntervalSince1970 - now.timeIntervalSince1970
        var scales: [Date] = []
        let calendar = Calendar.current
        
        guard totalSeconds > 0 else { return scales }
        
        if totalSeconds <= 3600 {
            var date = calendar.date(bySetting: .minute, value: (calendar.component(.minute, from: now) / 10 + 1) * 10, of: now) ?? now
            date = calendar.date(bySetting: .second, value: 0, of: date) ?? date
            while date < end { scales.append(date); date = date.addingTimeInterval(600) }
        } else if totalSeconds <= 86400 {
            var date = calendar.date(bySettingHour: calendar.component(.hour, from: now) + 1, minute: 0, second: 0, of: now) ?? now
            while date < end { scales.append(date); date = date.addingTimeInterval(3600) }
        } else {
            var date = calendar.startOfDay(for: now.addingTimeInterval(86400))
            while date < end { scales.append(date); date = date.addingTimeInterval(86400) }
        }
        return scales
    }
    
    private func getSize(width: Double) -> CGFloat {
        let needTime = todo.needTime - todo.actualFinishTime
        let total = todo.endDate.timeIntervalSince1970 - Date().timeIntervalSince1970
        guard total > 0 else { return width }
        let size = (Double(needTime) / total) * width
        return (size >= 0 && size <= width) ? size : width
    }
    
    private func getLocation(width: Double) -> CGFloat {
        let total = todo.endDate.timeIntervalSince1970 - Date().timeIntervalSince1970
        guard total > 0 else { return 0 }
        return ((todo.emergencyDate.timeIntervalSince1970 - Date().timeIntervalSince1970) / total) * width
    }
    
    private var taskBlock: some View { EmptyView() }

    private var cardContent: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    titleText
                    repeatTimesText
                    Text("截止日期").textTitleStyle()
                    Text("\(todo.endDate.localizedDateString) \(todo.endDate.timeString)")
                        .foregroundStyle(Color.blackGray).bold().font(.system(size: 12))
                }
                Spacer()
                VStack(alignment: .trailing) {
                    if todo.done { doneStatusView } else { activeStatusView }
                }
            }.padding()
        }
    }
    
    private var titleText: some View {
        Text("\(todo.content)\(prioritySuffix)")
            .textContentStyle()
            .padding(.bottom, todo.repeatTime == 0 ? 8 : 0)
    }
    
    private var prioritySuffix: String {
        switch todo.priority {
        case 1: return "!!!"; case 5: return "!!"; case 9: return "!"; default: return ""
        }
    }
    
    @ViewBuilder
    private var repeatTimesText: some View {
        if todo.repeatTime > 0 {
            Text("已坚持\(todo.times)\(["天", "周", "月"][todo.repeatTime - 1])")
                .textRepeatedTimesStyle()
        }
    }
    
    private var doneStatusView: some View {
        VStack(alignment: .trailing) {
            Text("实际完成时长").textTitleStyle()
            actualFinishTimeText
            Spacer()
            Text("完成时间").textTitleStyle()
            completionStatusText
        }
    }
    
    private var actualFinishTimeText: some View {
        let d = todo.actualFinishTime.decomposed
        return HStack {
            if d.days > 0 { Text("\(d.days)天").textTimeStyle() }
            if d.hours > 0 { Text("\(d.hours)时").textTimeStyle() }
            if d.minutes > 0 { Text("\(d.minutes)分").textTimeStyle() }
        }
    }
    
    @ViewBuilder
    private var completionStatusText: some View {
        let needTime = TimeInterval.from(days: todo.Day, hours: todo.Hour, minutes: todo.Min)
        let timeLeft = todo.endDate.timeIntervalSince1970 - todo.doneDate.timeIntervalSince1970
        if timeLeft - needTime > 0 {
            Text("\(todo.doneDate.localizedDateStringWithoutYear) \(todo.doneDate.timeString)").textTimeStyle()
        } else if timeLeft <= 0 {
            Text("已截止").textEndDateStyle()
        } else {
            Text("将截止").textEndDateStyle()
        }
    }
    
    private var activeStatusView: some View {
        VStack(alignment: .trailing) {
            Text("剩余所需时间").textTitleStyle()
            remainingTimeText
            Spacer()
            if todo.doing {
                Text("正在进行").textTitleStyle()
                Text("剩余\(formattedLeftTime)").textTimeStyle()
            } else {
                Text("剩余时间").textTitleStyle()
                leftTimeStatusText
            }
        }
    }
    
    private var remainingTimeText: some View {
        HStack {
            if todo.Day > 0 { Text("\(todo.Day)天").textTimeStyle() }
            if todo.Hour > 0 { Text("\(todo.Hour)时").textTimeStyle() }
            if todo.Min > 0 { Text("\(todo.Min)分").textTimeStyle() }
        }
    }
    
    @ViewBuilder
    private var leftTimeStatusText: some View {
        let leftTime = todoService.getLeftTime(for: todo)
        let d = leftTime.decomposed
        if leftTime <= 0 { Text("已截止").textEndDateStyle() }
        else if leftTime <= 60 { Text("将截止").textEndDateStyle() }
        else {
            HStack {
                if d.days > 0 { Text("\(d.days)天").textTimeStyle() }
                if d.hours > 0 { Text("\(d.hours)时").textTimeStyle() }
                if d.minutes > 0 { Text("\(d.minutes)分").textTimeStyle() }
            }
        }
    }
    
    private var formattedLeftTime: String {
        let d = todoService.getLeftTime(for: todo).decomposed
        var parts: [String] = []
        if d.days > 0 { parts.append("\(d.days)天") }
        if d.hours > 0 { parts.append("\(d.hours)时") }
        if d.minutes > 0 { parts.append("\(d.minutes)分") }
        return parts.joined()
    }
}

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
