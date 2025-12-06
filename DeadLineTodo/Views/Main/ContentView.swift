//
//  ContentView.swift
//  DeadLineTodo
//
//  Main content view with sidebar navigation
//

import SwiftUI
import SwiftData
import TipKit

struct ContentView: View {
    
    // MARK: - Properties
    
    @Query private var todoData: [TodoData] = []
    @Query private var userSettings: [UserSetting] = []
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var store: StoreKitManager
    
    @Binding var updated: Bool
    
    @State private var reminder = false
    @State private var calendar = false
    @State private var selectedOptions: [String] = []
    @State private var addTodoIsPresent = false
    @State private var sortOrder = SortDescriptor(\TodoData.priority)
    @State private var emergencyNum = 0
    @State private var isActionInProgress = true
    
    // MARK: - Navigation State
    
    @State private var currentView: ViewType = .todo
    
    enum ViewType {
        case todo, emergency, done, search, settings, statistics
    }
    
    // MARK: - Tips
    
    private let addTaskTip = AddContentTip()
    private let scoreTip = ScoreTip()
    
    // MARK: - Computed Properties
    
    private var tomorrowDate: Date {
        Date(timeIntervalSince1970: Date().timeIntervalSince1970 + 86400)
    }

    // MARK: - Body
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                HStack {
                    // 左侧边栏
                    SidebarView(
                        currentView: $currentView,
                        emergencyNum: emergencyNum,
                        weeklyScore: TodoService.shared.calculateWeeklyScore(from: todoData),
                        scoreTip: scoreTip
                    )
                    
                    // 右主视图
                    VStack {
                        mainContentView
                    }
                    .frame(maxHeight: .infinity)
                    .frame(width: geo.size.width - 50)
                    .background(Color.grayWhite1)
                    .offset(x: -8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("添加任务")
            }
            
            // ICP 备案信息
            if currentView == .settings {
                VStack {
                    Spacer()
                    Text("鄂ICP备2024036893号-1A")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.blackGray)
                        .padding()
                }
            }
        }
        .fullScreenCover(isPresented: $addTodoIsPresent) {
            AddTodoView(
                isPresented: $addTodoIsPresent,
                isActionInProgress: $isActionInProgress,
                todo: createNewTodo()
            )
        }
        .onAppear(perform: setupOnAppear)
        .onChange(of: store.purchasedCourses) { _, _ in
            Task { await checkPurchaseStatus() }
        }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContentView: some View {
        ZStack(alignment: .bottom) {
            // 内容视图
            Group {
                switch currentView {
                case .todo:
                    TodoListView(sort: sortOrder, addTodoIsPresent: $addTodoIsPresent, emergencyNum: $emergencyNum)
                case .emergency:
                    EmergencyView(sort: sortOrder, addTodoIsPresent: $addTodoIsPresent, emergencyNum: $emergencyNum)
                case .done:
                    DoneView(addTodoIsPresent: $addTodoIsPresent)
                case .search:
                    SearchTodoView(sort: sortOrder, addTodoIsPresent: $addTodoIsPresent, emergencyNum: $emergencyNum)
                case .settings:
                    SettingsView(reminder: $reminder, calendar: $calendar, selectedOptions: $selectedOptions)
                case .statistics:
                    StatisticsView()
                }
            }
            
            // 浮动按钮和排序菜单
            VStack {
                if ![.settings, .statistics, .done].contains(currentView) {
                    sortMenuView
                }
                Spacer()
                addButtonView
            }
        }
    }

    // MARK: - Subviews
    
    private var sortMenuView: some View {
        HStack {
            Spacer()
            Menu("", systemImage: "arrow.up.arrow.down") {
                Picker("排序", selection: $sortOrder) {
                    Text("优先级").tag(SortDescriptor(\TodoData.priority))
                    Text("添加日期").tag(SortDescriptor(\TodoData.addDate))
                    Text("截止日期").tag(SortDescriptor(\TodoData.endDate))
                    Text("开始日期").tag(SortDescriptor(\TodoData.startDoingDate))
                }
                .pickerStyle(.inline)
            }
            .bold()
            .accentColor(Color.myBlack)
            .padding(20)
            .padding(.top, 10)
        }
    }
    
    private var addButtonView: some View {
        HStack {
            Spacer()
            Button {
                addTodoIsPresent = true
                addTaskTip.invalidate(reason: .actionPerformed)
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.blackBlue2)
                        .frame(width: 70, height: 70)
                    Image(systemName: "plus")
                        .bold()
                        .font(.system(size: 25))
                        .foregroundColor(Color.grayWhite1)
                }
            }
            .padding()
            .padding(.horizontal)
            .padding(.bottom)
            .onAppear {
                Task {
                    await AddContentTip.presentEvent.donate()
                    if #available(iOS 18.0, *) {
                        await AddContentTip.presentEvent.donate()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createNewTodo() -> TodoData {
        TodoData(
            content: "",
            repeatTime: 0,
            priority: 1,
            endDate: tomorrowDate,
            addDate: Date(),
            doneDate: Date(),
            emergencyDate: Date(timeIntervalSince1970: tomorrowDate.timeIntervalSince1970 - 14400),
            startDoingDate: Date(),
            leftTime: 0,
            needTime: 7200,
            actualFinishTime: 0,
            lastTime: 0,
            initialNeedTime: 0,
            Day: 0,
            Hour: 0,
            Min: 0,
            Sec: 0,
            todo: true,
            done: false,
            emergency: false,
            doing: false,
            offset: 0,
            lastoffset: 0,
            score: 0,
            times: 0
        )
    }
    
    private func setupOnAppear() {
        // 使用低优先级队列处理初始化，让 UI 优先渲染
        DispatchQueue.global(qos: .utility).async {
            DispatchQueue.main.async {
                initializeUserSettings()
                countEmergencyTasks()
            }
        }
        
        // 权限请求延迟执行
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                requestPermissions()
                isActionInProgress = false
            }
        }
    }
    
    private func initializeUserSettings() {
        if userSettings.isEmpty {
            let setting = UserSetting(
                frequency: 1,
                reminder: reminder,
                hasPurchased: false,
                calendar: calendar,
                selectedOptions: selectedOptions
            )
            modelContext.insert(setting)
        } else {
            selectedOptions = userSettings[0].selectedOptions
        }
    }
    
    private func countEmergencyTasks() {
        emergencyNum = todoData.filter { $0.emergency }.count
    }
    
    private func requestPermissions() {
        NotificationService.shared.requestPermission()
        ReminderService.shared.requestPermission()
        CalendarService.shared.requestPermission()
    }
    
    private func checkPurchaseStatus() async {
        var hasPurchase = false
        
        for (index, product) in store.storeProducts.enumerated() where index < 4 {
            if (try? await store.isPurchased(product)) == true {
                hasPurchase = true
                break
            }
        }
        
        store.hasPurchased = hasPurchase
        
        guard !userSettings.isEmpty else { return }
        
        if store.hasPurchased {
            reminder = userSettings[0].reminder
            calendar = userSettings[0].calendar
            userSettings[0].hasPurchased = true
        } else {
            userSettings[0].reminder = false
            userSettings[0].calendar = false
            userSettings[0].hasPurchased = false
        }
    }
}
