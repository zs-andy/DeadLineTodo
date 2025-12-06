//
//  StatisticsView.swift
//  DeadLineTodo
//
//  Statistics and charts view
//

import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    
    @Query private var todoData: [TodoData]
    @Query private var userSettings: [UserSetting]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var store: StoreKitManager
    
    @State private var storeView = false
    
    // Chart selection states
    @State private var isWeekPoint = true
    @State private var isMonthPoint = false
    @State private var isYearPoint = false
    
    @State private var isWeekTimeTaken = true
    @State private var isMonthTimeTaken = false
    @State private var isYearTimeTaken = false
    
    @State private var isWeekTimeDifference = true
    @State private var isMonthTimeDifference = false
    @State private var isYearTimeDifference = false
    
    // 分段加载状态
    @State private var isLoadingOverview = true
    @State private var isLoadingHeatMap = true
    @State private var isLoadingEfficiency = true
    @State private var isLoadingWorkingTime = true
    @State private var isLoadingTimeDiff = true
    
    // Async loaded data
    @State private var weekDoneNum = 0
    @State private var weekTodoNum = 0  // 本周未完成任务数
    @State private var heatChartData: [Double] = []
    @State private var weekLineChartData: [LineWeekData] = []
    @State private var monthLineChartData: [LineMonthData] = []
    @State private var yearLineChartData: [LineYearData] = []
    @State private var workingWeekTime: [WorkingTimeWeekData] = []
    @State private var workingMonthTime: [WorkingTimeMonthData] = []
    @State private var workingYearTime: [WorkingTimeYearData] = []
    @State private var weekTimeDifference: [TimeDifferenceWeekData] = []
    @State private var monthTimeDifference: [TimeDifferenceMonthData] = []
    @State private var yearTimeDifference: [TimeDifferenceYearData] = []
    
    // 当前宽度用于热力图
    @State private var currentColumns: Int = 0
    @State private var hasLoaded = false
    
    private let rows = 7
    
    // 示例数据
    private let sampleLineWeekData: [LineWeekData] = [
        .init(day: "1", value: 44),
        .init(day: "2", value: 70),
        .init(day: "3", value: 66),
        .init(day: "4", value: 77),
        .init(day: "5", value: 49),
        .init(day: "6", value: 89),
        .init(day: "7", value: 92)
    ]
    
    private let sampleHeatData: [Double] = [
        0.3, 0.4, 0.4, 0.4, 0.1, 0.5, 0.0,
        0.1, 0.0, 0.2, 0.2, 0.2, 0.0, 0.2,
        0.2, 0.5, 0.4, 0.2, 0.4, 0.5, 0.2,
        0.2, 0.4, 0.3, 0.3, 0.2, 0.4, 0.0,
        0.0, 0.5, 0.4, 0.3, 0.5, 0.3, 0.0,
        0.0, 0.5, 0.3, 0.3, 0.0, 0.3, 0.0,
        0.5, 0.3, 0.3, 0.4, 0.5, 0.5, 0.3,
        0.4, 0.1, 0.4, 0.2, 0.5, 0.1, 0.4,
        0.2, 0.5, 0.4, 0.3, 0.5, 0.0, 0.4,
        0.3, 0.2, 0.1, 0.5, 0.2, 0.0, 0.2,
        0.5, 0.5, 0.3, 0.4, 0.0, 0.3, 0.3,
        0.1, 0.2, 0.5, 0.2, 0.1, 0.4, 0.4
    ]
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // 标题
                HStack {
                    Text(LocalizedStringKey("统计"))
                        .font(.system(size: 30))
                        .bold()
                        .padding(20)
                        .foregroundStyle(Color.myBlack)
                    Spacer()
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 数据概览卡片
                        overviewSection
                        
                        // 热力图
                        chartCard {
                            heatMapSection(geo: geo)
                        }
                        
                        // 效率分数
                        chartCard {
                            efficiencyChartSection(geo: geo)
                        }
                        
                        // 完成时间
                        chartCard {
                            workingTimeChartSection(geo: geo)
                        }
                        
                        // 时间差
                        chartCard {
                            timeDifferenceChartSection(geo: geo)
                        }
                        
                        // 购买提示
                        if !store.hasPurchased {
                            purchasePrompt
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 150)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onAppear {
                let columns = getColumns(width: geo.size.width)
                if !hasLoaded {
                    hasLoaded = true
                    currentColumns = columns
                    // 延迟加载数据，让 UI 先渲染完成
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        loadAllData(columns: columns)
                    }
                }
            }
            .onChange(of: geo.size.width) { _, newWidth in
                let newColumns = getColumns(width: newWidth)
                // 只有列数真正变化时才重新加载热力图
                if newColumns != currentColumns {
                    currentColumns = newColumns
                    // 延迟加载，让 UI 先完成布局
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        reloadHeatMapData(columns: newColumns)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $storeView) {
            StoreView(isPresented: $storeView)
        }
    }
    
    // MARK: - Loading View (骨架屏效果)
    
    private var loadingView: some View {
        SkeletonLoadingView()
            .frame(maxWidth: .infinity)
            .frame(height: 100)
    }
    
    private var chartLoadingView: some View {
        SkeletonLoadingView()
            .frame(maxWidth: .infinity)
            .frame(height: 180)
    }

    // MARK: - Overview Section
    
    private var overviewSection: some View {
        HStack(spacing: 12) {
            if isLoadingOverview {
                SkeletonLoadingView()
                    .frame(height: 100)
                SkeletonLoadingView()
                    .frame(height: 100)
            } else {
                overviewCard(
                    title: LocalizedStringKey("本周完成"),
                    value: "\(weekDoneNum)",
                    unit: LocalizedStringKey("项"),
                    icon: "checkmark.circle.fill",
                    color: .green2
                )
                
                overviewCard(
                    title: LocalizedStringKey("本周待办"),
                    value: "\(weekTodoNum)",
                    unit: LocalizedStringKey("项"),
                    icon: "list.bullet.circle.fill",
                    color: .blackBlue2
                )
            }
        }
    }
    
    private func overviewCard(title: LocalizedStringKey, value: String, unit: LocalizedStringKey, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
            
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color.myBlack)
                Text(unit)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.blackGray)
            }
            
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(Color.blackGray)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.grayWhite2.opacity(0.6))
        )
    }
    
    // MARK: - Chart Card Wrapper
    
    private func chartCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.grayWhite2.opacity(0.6))
        )
    }
    
    // MARK: - Purchase Prompt
    
    private var purchasePrompt: some View {
        Button {
            storeView = true
        } label: {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                    Text(LocalizedStringKey("以上为样例数据"))
                        .font(.system(size: 11, weight: .medium))
                }
                Text(LocalizedStringKey("购买高级功能"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.blackBlue2)
            }
            .foregroundStyle(Color.blackGray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.grayWhite2.opacity(0.6))
            )
        }
    }
    
    // MARK: - Heat Map Section
    
    private func heatMapSection(geo: GeometryProxy) -> some View {
        let columns = getColumns(width: geo.size.width)
        
        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "calendar", title: LocalizedStringKey("完成热力图"))
            
            if isLoadingHeatMap {
                chartLoadingView
            } else if store.hasPurchased {
                if heatChartData.count == columns * 7 {
                    ContributionChartView(
                        data: heatChartData,
                        rows: rows,
                        columns: columns,
                        targetValue: 1,
                        blockColor: .green2
                    )
                    .padding(.top, 4)
                }
            } else {
                // 动态生成足够的样例数据以填满屏幕宽度
                let sampleData = generateSampleHeatData(columns: columns)
                ContributionChartView(
                    data: sampleData,
                    rows: rows,
                    columns: columns,
                    targetValue: 1.0,
                    blockColor: .green2
                )
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Efficiency Chart Section
    
    private func efficiencyChartSection(geo: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                sectionHeader(
                    icon: "chart.xyaxis.line",
                    title: LocalizedStringKey("效率分数")
                )
                Spacer()
                periodPicker(week: $isWeekPoint, month: $isMonthPoint, year: $isYearPoint)
            }
            
            if isLoadingEfficiency {
                chartLoadingView
            } else if isWeekPoint {
                if store.hasPurchased {
                    weekLineChart(geo: geo, data: weekLineChartData)
                } else {
                    weekLineChart(geo: geo, data: sampleLineWeekData)
                }
            } else if isMonthPoint {
                monthLineChart(geo: geo)
            } else {
                yearLineChart(geo: geo)
            }
        }
    }
    
    // MARK: - Working Time Chart Section
    
    private func workingTimeChartSection(geo: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                sectionHeader(
                    icon: "clock.badge.checkmark",
                    title: LocalizedStringKey("完成时间")
                )
                Spacer()
                periodPicker(week: $isWeekTimeTaken, month: $isMonthTimeTaken, year: $isYearTimeTaken)
            }
            
            if isLoadingWorkingTime {
                chartLoadingView
            } else if isWeekTimeTaken {
                workingWeekChart(geo: geo, purchased: store.hasPurchased)
            } else if isMonthTimeTaken {
                workingMonthChart(geo: geo)
            } else {
                workingYearChart(geo: geo)
            }
        }
    }
    
    // MARK: - Time Difference Chart Section
    
    private func timeDifferenceChartSection(geo: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                sectionHeader(
                    icon: "chart.bar.xaxis",
                    title: LocalizedStringKey("时间差")
                )
                Spacer()
                periodPicker(week: $isWeekTimeDifference, month: $isMonthTimeDifference, year: $isYearTimeDifference)
            }
            
            if isLoadingTimeDiff {
                chartLoadingView
            } else if isWeekTimeDifference {
                timeDiffWeekChart(geo: geo, purchased: store.hasPurchased)
            } else if isMonthTimeDifference {
                timeDiffMonthChart(geo: geo)
            } else {
                timeDiffYearChart(geo: geo)
            }
        }
    }

    // MARK: - Section Header
    
    private func sectionHeader(icon: String, title: LocalizedStringKey) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.blackBlue2)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.myBlack)
                .lineLimit(1)
        }
    }
    
    // MARK: - Charts
    
    private func weekLineChart(geo: GeometryProxy, data: [LineWeekData]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Chart(data) { item in
                LineMark(x: .value("day", item.day), y: .value("total", item.value))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.creamBlue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                AreaMark(x: .value("day", item.day), y: .value("total", item.value))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.creamBlue.opacity(0.3), Color.creamBlue.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .frame(width: max(geo.size.width - 72, 300), height: 180)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
    }

    private func monthLineChart(geo: GeometryProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Chart(monthLineChartData) { item in
                LineMark(x: .value("Day", item.day), y: .value("Score", item.value))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.creamBlue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                AreaMark(x: .value("Day", item.day), y: .value("Score", item.value))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.creamBlue.opacity(0.3), Color.creamBlue.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .frame(width: max(getMonthChartWidth(geoWidth: geo.size.width), 300), height: 180)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
    }
    
    private func yearLineChart(geo: GeometryProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Chart(yearLineChartData) { item in
                LineMark(x: .value("Month", item.month), y: .value("Score", item.value))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.creamBlue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                AreaMark(x: .value("Month", item.month), y: .value("Score", item.value))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.creamBlue.opacity(0.3), Color.creamBlue.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .frame(width: max(geo.size.width - 72, 300), height: 180)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
    }
    
    private func workingWeekChart(geo: GeometryProxy, purchased: Bool) -> some View {
        HStack(alignment: .center, spacing: 8) {
            if purchased {
                Chart(workingWeekTime) { item in
                    BarMark(x: .value("day", item.day), y: .value("total", item.value))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.creamBlue, Color.creamBlue.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(4)
                }
                .frame(width: max(geo.size.width - 92, 280), height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                Chart(sampleLineWeekData) { item in
                    BarMark(x: .value("day", item.day), y: .value("total", item.value))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.creamBlue, Color.creamBlue.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(4)
                }
                .frame(width: max(geo.size.width - 92, 280), height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
            timeRangeLabel(range: workingWeekTime.first?.range ?? "S")
        }
    }
    
    private func workingMonthChart(geo: GeometryProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 8) {
                Chart(workingMonthTime) { item in
                    BarMark(x: .value("Day", item.day), y: .value("Time", item.value))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.creamBlue, Color.creamBlue.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(4)
                }
                .frame(width: max(getMonthChartWidth(geoWidth: geo.size.width) - 40, 300), height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                timeRangeLabel(range: workingMonthTime.first?.range ?? "S")
            }
        }
    }
    
    private func workingYearChart(geo: GeometryProxy) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Chart(workingYearTime) { item in
                BarMark(x: .value("Month", item.month), y: .value("Time", item.value))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.creamBlue, Color.creamBlue.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(4)
            }
            .frame(width: max(geo.size.width - 92, 280), height: 180)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            timeRangeLabel(range: workingYearTime.first?.range ?? "S")
        }
    }
    
    private func timeDiffWeekChart(geo: GeometryProxy, purchased: Bool) -> some View {
        HStack(alignment: .center, spacing: 8) {
            if purchased {
                Chart(weekTimeDifference) { item in
                    BarMark(x: .value("day", item.day), y: .value("total", item.value))
                        .foregroundStyle(item.value >= 0 ? Color.green2 : Color.creamBrown)
                        .cornerRadius(4)
                }
                .frame(width: max(geo.size.width - 92, 280), height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                Chart(sampleLineWeekData) { item in
                    BarMark(x: .value("day", item.day), y: .value("total", item.value))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.creamBlue, Color.creamBlue.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(4)
                }
                .frame(width: max(geo.size.width - 92, 280), height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
            timeRangeLabel(range: weekTimeDifference.first?.range ?? "S")
        }
    }
    
    private func timeDiffMonthChart(geo: GeometryProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 8) {
                Chart(monthTimeDifference) { item in
                    BarMark(x: .value("Day", item.day), y: .value("Diff", item.value))
                        .foregroundStyle(item.value >= 0 ? Color.green2 : Color.creamBrown)
                        .cornerRadius(4)
                }
                .frame(width: max(getMonthChartWidth(geoWidth: geo.size.width) - 40, 300), height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                timeRangeLabel(range: monthTimeDifference.first?.range ?? "S")
            }
        }
    }
    
    private func timeDiffYearChart(geo: GeometryProxy) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Chart(yearTimeDifference) { item in
                BarMark(x: .value("Month", item.month), y: .value("Diff", item.value))
                    .foregroundStyle(item.value >= 0 ? Color.green2 : Color.creamBrown)
                    .cornerRadius(4)
            }
            .frame(width: max(geo.size.width - 92, 280), height: 180)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            timeRangeLabel(range: yearTimeDifference.first?.range ?? "S")
        }
    }
    
    // MARK: - Helper Views
    
    private func timeRangeLabel(range: String) -> some View {
        Group {
            if range == "S" {
                Text(LocalizedStringKey("秒"))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.gray)
                    .rotationEffect(Angle(degrees: 90))
                    .offset(x: -5)
            } else if range == "M" {
                Text(LocalizedStringKey("分钟"))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.gray)
                    .rotationEffect(Angle(degrees: 90))
                    .offset(x: -5)
            } else if range == "H" {
                Text(LocalizedStringKey("小时"))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.gray)
                    .rotationEffect(Angle(degrees: 90))
                    .offset(x: -5)
            }
        }
    }
    
    private func getMonthChartWidth(geoWidth: CGFloat) -> CGFloat {
        if geoWidth - 60 > 1000 {
            return geoWidth - 60
        } else {
            return 1000
        }
    }
    
    private func periodPicker(week: Binding<Bool>, month: Binding<Bool>, year: Binding<Bool>) -> some View {
        HStack(spacing: 4) {
            periodButton(text: "W", isSelected: week.wrappedValue) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    week.wrappedValue = true
                    month.wrappedValue = false
                    year.wrappedValue = false
                }
            }
            
            periodButton(text: "M", isSelected: month.wrappedValue) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if store.hasPurchased {
                        week.wrappedValue = false
                        month.wrappedValue = true
                        year.wrappedValue = false
                    }
                }
            }
            
            periodButton(text: "Y", isSelected: year.wrappedValue) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if store.hasPurchased {
                        week.wrappedValue = false
                        month.wrappedValue = false
                        year.wrappedValue = true
                    }
                }
            }
        }
        .padding(3)
        .background(Color.white)
        .cornerRadius(8)
    }
    
    private func periodButton(text: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white : Color.blackGray)
                .frame(width: 32, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isSelected ? Color.blackBlue2 : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data Loading
    
    private func getColumns(width: CGFloat) -> Int {
        max(Int(width / 21) - 3, 1)
    }
    
    /// 生成样例热力图数据，填满指定列数
    private func generateSampleHeatData(columns: Int) -> [Double] {
        let totalCells = columns * 7
        var data = [Double]()
        for i in 0..<totalCells {
            // 使用固定种子生成伪随机数据，确保每次显示一致
            let seed = Double(i * 17 % 100) / 100.0
            data.append(seed)
        }
        return data
    }
    
    /// 并行加载所有数据，使用低优先级避免阻塞 UI
    private func loadAllData(columns: Int) {
        let localData = Array(todoData)
        
        // 使用 utility 优先级，让 UI 渲染优先
        DispatchQueue.global(qos: .utility).async {
            // 预处理：按日期分组，避免重复遍历
            let doneData = localData.filter { $0.done }
            let todoData = localData.filter { $0.todo || $0.emergency }
            
            // 计算所有数据
            let doneNum = self.calcWeekDoneNum(doneData)
            let todoNum = self.calcWeekTodoNum(todoData)
            let heatChart = self.calcHeatChartData(doneData, columns: columns)
            let weekLine = self.calcWeekLineChartData(doneData)
            let monthLine = self.calcMonthLineChartData(doneData)
            let yearLine = self.calcYearLineChartData(doneData)
            let workWeek = self.calcWorkingWeekTime(doneData)
            let workMonth = self.calcWorkingMonthTime(doneData)
            let workYear = self.calcWorkingYearTime(doneData)
            let diffWeek = self.calcTimeDifferenceWeek(doneData)
            let diffMonth = self.calcTimeDifferenceMonth(doneData)
            let diffYear = self.calcTimeDifferenceYear(doneData)
            
            DispatchQueue.main.async {
                self.weekDoneNum = doneNum
                self.weekTodoNum = todoNum
                self.heatChartData = heatChart
                self.weekLineChartData = weekLine
                self.monthLineChartData = monthLine
                self.yearLineChartData = yearLine
                self.workingWeekTime = workWeek
                self.workingMonthTime = workMonth
                self.workingYearTime = workYear
                self.weekTimeDifference = diffWeek
                self.monthTimeDifference = diffMonth
                self.yearTimeDifference = diffYear
                
                self.isLoadingOverview = false
                self.isLoadingHeatMap = false
                self.isLoadingEfficiency = false
                self.isLoadingWorkingTime = false
                self.isLoadingTimeDiff = false
            }
        }
    }
    
    /// 仅重新加载热力图数据（列数变化时）
    private func reloadHeatMapData(columns: Int) {
        isLoadingHeatMap = true
        let doneData = todoData.filter { $0.done }
        
        // 使用 utility 优先级，让 UI 渲染优先
        DispatchQueue.global(qos: .utility).async {
            let heatChart = self.calcHeatChartData(doneData, columns: columns)
            DispatchQueue.main.async {
                self.heatChartData = heatChart
                self.isLoadingHeatMap = false
            }
        }
    }

    // MARK: - Data Calculations (优化版：接收已过滤的 done 数据)
    
    private func calcWeekDoneNum(_ doneData: [TodoData]) -> Int {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }
        let weekStartTime = weekStart.timeIntervalSince1970
        return doneData.filter { $0.doneDate.timeIntervalSince1970 > weekStartTime }.count
    }
    
    /// 计算本周未完成任务数（截止日期在本周内的待办任务）
    private func calcWeekTodoNum(_ todoData: [TodoData]) -> Int {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return 0 }
        let weekStart = weekInterval.start.timeIntervalSince1970
        let weekEnd = weekInterval.end.timeIntervalSince1970
        return todoData.filter { 
            $0.endDate.timeIntervalSince1970 >= weekStart && 
            $0.endDate.timeIntervalSince1970 < weekEnd 
        }.count
    }
    
    /// 计算热力图数据（类似 GitHub commit，显示每天完成的任务数量）
    private func calcHeatChartData(_ doneData: [TodoData], columns: Int) -> [Double] {
        guard let tomorrowStart = Date().tomorrowStart else { return [] }
        let totalDays = columns * 7
        let allTime = TimeInterval(totalDays * 86400)
        let startTime = tomorrowStart.timeIntervalSince1970 - allTime
        
        // 预先按天分组，统计每天完成的任务数量
        var dayBuckets = [Int](repeating: 0, count: totalDays)
        for todo in doneData {
            let dayIndex = Int((todo.doneDate.timeIntervalSince1970 - startTime) / 86400)
            if dayIndex >= 0 && dayIndex < totalDays {
                dayBuckets[dayIndex] += 1
            }
        }
        
        // 找出最大值用于归一化
        let maxCount = dayBuckets.max() ?? 1
        let normalizer = max(Double(maxCount), 1.0)
        
        return dayBuckets.map { count in
            Double(count) / normalizer
        }
    }
    
    private func calcWeekLineChartData(_ doneData: [TodoData]) -> [LineWeekData] {
        var weekday = Calendar.current.component(.weekday, from: Date())
        weekday = weekday == 1 ? 7 : weekday - 1
        guard let tomorrowStart = Date().tomorrowStart else { return [] }
        let weekStart = tomorrowStart.timeIntervalSince1970 - Double(weekday * 86400)
        
        // 预先按天分组
        var dayBuckets = [[TodoData]](repeating: [], count: 7)
        for todo in doneData {
            let dayIndex = Int((todo.doneDate.timeIntervalSince1970 - weekStart) / 86400)
            if dayIndex >= 0 && dayIndex < 7 {
                dayBuckets[dayIndex].append(todo)
            }
        }
        
        var lastScore = 0
        return (0..<7).map { index in
            let todos = dayBuckets[index]
            if !todos.isEmpty {
                lastScore = todos.reduce(0) { $0 + $1.score } / todos.count
            }
            return LineWeekData(day: "\(index + 1)", value: lastScore)
        }
    }
    
    private func calcMonthLineChartData(_ doneData: [TodoData]) -> [LineMonthData] {
        let dayNumber = Calendar.current.component(.day, from: Date())
        guard let tomorrowStart = Date().tomorrowStart else { return [] }
        let monthStart = tomorrowStart.timeIntervalSince1970 - Double(dayNumber * 86400)
        let daysInMonth = Date.daysInCurrentMonth
        
        // 预先按天分组
        var dayBuckets = [[TodoData]](repeating: [], count: daysInMonth)
        for todo in doneData {
            let dayIndex = Int((todo.doneDate.timeIntervalSince1970 - monthStart) / 86400)
            if dayIndex >= 0 && dayIndex < daysInMonth {
                dayBuckets[dayIndex].append(todo)
            }
        }
        
        var lastScore = 0
        return (0..<daysInMonth).map { index in
            let todos = dayBuckets[index]
            if !todos.isEmpty {
                lastScore = todos.reduce(0) { $0 + $1.score } / todos.count
            }
            return LineMonthData(day: "\(index + 1)th", value: lastScore)
        }
    }
    
    private func calcYearLineChartData(_ doneData: [TodoData]) -> [LineYearData] {
        let year = Calendar.current.component(.year, from: Date())
        
        // 预先按月分组
        var monthBuckets = [[TodoData]](repeating: [], count: 12)
        for todo in doneData {
            let month = Calendar.current.component(.month, from: todo.doneDate)
            let todoYear = Calendar.current.component(.year, from: todo.doneDate)
            if todoYear == year && month >= 1 && month <= 12 {
                monthBuckets[month - 1].append(todo)
            }
        }
        
        var lastScore = 0
        return (0..<12).map { index in
            let todos = monthBuckets[index]
            if !todos.isEmpty {
                lastScore = todos.reduce(0) { $0 + $1.score } / todos.count
            }
            return LineYearData(month: "\(index + 1)", value: lastScore)
        }
    }
    
    private func calcWorkingWeekTime(_ doneData: [TodoData]) -> [WorkingTimeWeekData] {
        var weekday = Calendar.current.component(.weekday, from: Date())
        weekday = weekday == 1 ? 7 : weekday - 1
        guard let tomorrowStart = Date().tomorrowStart else { return [] }
        let weekStart = tomorrowStart.timeIntervalSince1970 - Double(weekday * 86400)
        
        var dayBuckets = [[TodoData]](repeating: [], count: 7)
        for todo in doneData {
            let dayIndex = Int((todo.doneDate.timeIntervalSince1970 - weekStart) / 86400)
            if dayIndex >= 0 && dayIndex < 7 {
                dayBuckets[dayIndex].append(todo)
            }
        }
        
        var result = (0..<7).map { index in
            let time = dayBuckets[index].reduce(0.0) { $0 + $1.actualFinishTime }
            return WorkingTimeWeekData(day: "\(index + 1)", value: time, range: "S")
        }
        normalizeTimeData(&result)
        return result
    }
    
    private func calcWorkingMonthTime(_ doneData: [TodoData]) -> [WorkingTimeMonthData] {
        let dayNumber = Calendar.current.component(.day, from: Date())
        guard let tomorrowStart = Date().tomorrowStart else { return [] }
        let monthStart = tomorrowStart.timeIntervalSince1970 - Double(dayNumber * 86400)
        let daysInMonth = Date.daysInCurrentMonth
        
        var dayBuckets = [[TodoData]](repeating: [], count: daysInMonth)
        for todo in doneData {
            let dayIndex = Int((todo.doneDate.timeIntervalSince1970 - monthStart) / 86400)
            if dayIndex >= 0 && dayIndex < daysInMonth {
                dayBuckets[dayIndex].append(todo)
            }
        }
        
        var result = (0..<daysInMonth).map { index in
            let time = dayBuckets[index].reduce(0.0) { $0 + $1.actualFinishTime }
            return WorkingTimeMonthData(day: "\(index + 1)th", value: time, range: "S")
        }
        normalizeMonthTimeData(&result)
        return result
    }
    
    private func calcWorkingYearTime(_ doneData: [TodoData]) -> [WorkingTimeYearData] {
        let year = Calendar.current.component(.year, from: Date())
        
        var monthBuckets = [[TodoData]](repeating: [], count: 12)
        for todo in doneData {
            let month = Calendar.current.component(.month, from: todo.doneDate)
            let todoYear = Calendar.current.component(.year, from: todo.doneDate)
            if todoYear == year && month >= 1 && month <= 12 {
                monthBuckets[month - 1].append(todo)
            }
        }
        
        var result = (0..<12).map { index in
            let time = monthBuckets[index].reduce(0.0) { $0 + $1.actualFinishTime }
            return WorkingTimeYearData(month: "\(index + 1)", value: time, range: "S")
        }
        normalizeYearTimeData(&result)
        return result
    }
    
    private func calcTimeDifferenceWeek(_ doneData: [TodoData]) -> [TimeDifferenceWeekData] {
        var weekday = Calendar.current.component(.weekday, from: Date())
        weekday = weekday == 1 ? 7 : weekday - 1
        guard let tomorrowStart = Date().tomorrowStart else { return [] }
        let weekStart = tomorrowStart.timeIntervalSince1970 - Double(weekday * 86400)
        
        var dayBuckets = [[TodoData]](repeating: [], count: 7)
        for todo in doneData where todo.actualFinishTime > 0 {
            let dayIndex = Int((todo.doneDate.timeIntervalSince1970 - weekStart) / 86400)
            if dayIndex >= 0 && dayIndex < 7 {
                dayBuckets[dayIndex].append(todo)
            }
        }
        
        var result = (0..<7).map { index in
            let diff = dayBuckets[index].reduce(0.0) { $0 + ($1.needTime - $1.actualFinishTime) }
            return TimeDifferenceWeekData(day: "\(index + 1)", value: diff, range: "S")
        }
        normalizeTimeDiffData(&result)
        return result
    }
    
    private func calcTimeDifferenceMonth(_ doneData: [TodoData]) -> [TimeDifferenceMonthData] {
        let dayNumber = Calendar.current.component(.day, from: Date())
        guard let tomorrowStart = Date().tomorrowStart else { return [] }
        let monthStart = tomorrowStart.timeIntervalSince1970 - Double(dayNumber * 86400)
        let daysInMonth = Date.daysInCurrentMonth
        
        var dayBuckets = [[TodoData]](repeating: [], count: daysInMonth)
        for todo in doneData where todo.actualFinishTime > 0 {
            let dayIndex = Int((todo.doneDate.timeIntervalSince1970 - monthStart) / 86400)
            if dayIndex >= 0 && dayIndex < daysInMonth {
                dayBuckets[dayIndex].append(todo)
            }
        }
        
        var result = (0..<daysInMonth).map { index in
            let diff = dayBuckets[index].reduce(0.0) { $0 + ($1.needTime - $1.actualFinishTime) }
            return TimeDifferenceMonthData(day: "\(index + 1)th", value: diff, range: "S")
        }
        normalizeMonthTimeDiffData(&result)
        return result
    }
    
    private func calcTimeDifferenceYear(_ doneData: [TodoData]) -> [TimeDifferenceYearData] {
        let year = Calendar.current.component(.year, from: Date())
        
        var monthBuckets = [[TodoData]](repeating: [], count: 12)
        for todo in doneData where todo.actualFinishTime > 0 {
            let month = Calendar.current.component(.month, from: todo.doneDate)
            let todoYear = Calendar.current.component(.year, from: todo.doneDate)
            if todoYear == year && month >= 1 && month <= 12 {
                monthBuckets[month - 1].append(todo)
            }
        }
        
        var result = (0..<12).map { index in
            let diff = monthBuckets[index].reduce(0.0) { $0 + ($1.needTime - $1.actualFinishTime) }
            return TimeDifferenceYearData(month: "\(index + 1)", value: diff, range: "S")
        }
        normalizeYearTimeDiffData(&result)
        return result
    }
    
    // MARK: - Normalize Helpers
    
    private func normalizeTimeData(_ data: inout [WorkingTimeWeekData]) {
        let max = data.map { $0.value }.max() ?? 0
        if max >= 3600 {
            for i in data.indices { data[i].value /= 3600; data[i].range = "H" }
        } else if max >= 60 {
            for i in data.indices { data[i].value /= 60; data[i].range = "M" }
        }
    }
    
    private func normalizeMonthTimeData(_ data: inout [WorkingTimeMonthData]) {
        let max = data.map { $0.value }.max() ?? 0
        if max >= 3600 {
            for i in data.indices { data[i].value /= 3600; data[i].range = "H" }
        } else if max >= 60 {
            for i in data.indices { data[i].value /= 60; data[i].range = "M" }
        }
    }
    
    private func normalizeYearTimeData(_ data: inout [WorkingTimeYearData]) {
        let max = data.map { $0.value }.max() ?? 0
        if max >= 3600 {
            for i in data.indices { data[i].value /= 3600; data[i].range = "H" }
        } else if max >= 60 {
            for i in data.indices { data[i].value /= 60; data[i].range = "M" }
        }
    }
    
    private func normalizeTimeDiffData(_ data: inout [TimeDifferenceWeekData]) {
        let max = data.map { abs($0.value) }.max() ?? 0
        if max >= 3600 {
            for i in data.indices { data[i].value /= 3600; data[i].range = "H" }
        } else if max >= 60 {
            for i in data.indices { data[i].value /= 60; data[i].range = "M" }
        }
    }
    
    private func normalizeMonthTimeDiffData(_ data: inout [TimeDifferenceMonthData]) {
        let max = data.map { abs($0.value) }.max() ?? 0
        if max >= 3600 {
            for i in data.indices { data[i].value /= 3600; data[i].range = "H" }
        } else if max >= 60 {
            for i in data.indices { data[i].value /= 60; data[i].range = "M" }
        }
    }
    
    private func normalizeYearTimeDiffData(_ data: inout [TimeDifferenceYearData]) {
        let max = data.map { abs($0.value) }.max() ?? 0
        if max >= 3600 {
            for i in data.indices { data[i].value /= 3600; data[i].range = "H" }
        } else if max >= 60 {
            for i in data.indices { data[i].value /= 60; data[i].range = "M" }
        }
    }
}

// MARK: - Skeleton Loading View

private struct SkeletonLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.1),
                        Color.gray.opacity(0.2),
                        Color.gray.opacity(0.1)
                    ],
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}
