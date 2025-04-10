//
//  ContentView.swift
//  DeadLineTodo
//
//  Created by Andy on 2024/1/17.
//

import SwiftUI
import SwiftData
import NotificationCenter
import EventKit
import TipKit

struct ContentView: View {
    @Query var tododata: [TodoData] = []
    @Query var userSetting: [UserSetting] = []
    @State var reminder: Bool = false
    @State var calendar: Bool = false
    @State var AddTodoIsPresent = false
    @State private var sortOrder = SortDescriptor(\TodoData.priority)
    
    @State var IsTodoView: Bool = true
    @State var IsEmergencyView: Bool = false
    @State var IsDoneView: Bool = false
    @State var IsSearchView: Bool = false
    @State var IsSettingView: Bool = false
    @State var IsStatisticsView: Bool = false
    @State var isActionInProgress = true
    
    @Binding var updated: Bool
    
    @State var EmergencyNum: Int = 0
    
    @State var tomorrowDate: Date = Date(timeIntervalSince1970: Date().timeIntervalSince1970 + TimeInterval(24*60*60))
    
    @State var selectedOptions: [String] = []
    
    @Environment(\.modelContext) var modelContext
    
    @EnvironmentObject var store: StoreKitManager
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    let addTaskTip = AddContentTip()
    
    let scoreTip = ScoreTip()
    
    var body: some View {
        ZStack{
            GeometryReader { geo in
                HStack{
                    VStack{//左侧边栏
                        ZStack(alignment: .top){
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(Color.creamBlue)
                                .padding(.horizontal, 5)
                            VStack{
                                Button(action: {
                                    withAnimation(.default){
                                        IsSearchView = false
                                        IsDoneView = false
                                        IsTodoView = false
                                        IsEmergencyView = false
                                        IsSettingView = true
                                        IsStatisticsView = false
                                    }
                                }){
                                    ZStack{
                                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                                            .fill(IsSettingView ? Color.blackBlue2 : Color.creamBlue)
                                            .frame(height: 50)
                                            .padding(.horizontal, 5)
                                        Image(systemName: "gearshape.fill")
                                            .foregroundStyle(IsSettingView ? Color.grayWhite1 : Color.blackBlue2)
                                    }
                                }
                                Button(action: {
                                    if !isActionInProgress {
                                        isActionInProgress = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            isActionInProgress = false
                                        }
                                        IsDoneView = false
                                        IsTodoView = false
                                        IsEmergencyView = false
                                        IsSettingView = false
                                        IsStatisticsView = false
                                        withAnimation(.default){
                                            IsSearchView = true
                                        }
                                    }
                                }){
                                    ZStack{
                                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                                            .fill(IsSearchView ? Color.blackBlue2 : Color.creamBlue)
                                            .frame(height: 50)
                                            .padding(.horizontal, 5)
                                        Image(systemName: "magnifyingglass")
                                            .bold()
                                            .foregroundStyle(IsSearchView ? Color.grayWhite1 : Color.blackBlue2)
                                    }
                                }
                                Button(action: {
                                    if !isActionInProgress {
                                        isActionInProgress = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            isActionInProgress = false
                                        }
                                        IsEmergencyView = false
                                        IsDoneView = false
                                        IsSearchView = false
                                        IsSettingView = false
                                        IsStatisticsView = false
                                        withAnimation(.default){
                                            IsTodoView = true
                                        }
                                    }
                                }){
                                    ZStack{
                                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                                            .fill(IsTodoView ? Color.blackBlue2 : Color.creamBlue)
                                            .frame(height: 85)
                                            .padding(.horizontal, 5)
    //                                        .shadow(color: Color.blackBlue2, radius: IsTodoView ? 5 : 0)
                                        VStack{
                                            Text("待")
                                                .bold()
                                                .foregroundStyle(IsTodoView ? Color.grayWhite1 : Color.blackBlue2)
                                            Text("办")
                                                .bold()
                                                .foregroundStyle(IsTodoView ? Color.grayWhite1 : Color.blackBlue2)
                                        }
                                    }
                                }
                                .padding(.bottom,-2)
                                Button(action: {
                                    if !isActionInProgress {
                                        isActionInProgress = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            isActionInProgress = false
                                        }
                                        IsDoneView = false
                                        IsSearchView = false
                                        IsSettingView = false
                                        IsStatisticsView = false
                                        IsTodoView = false
                                        withAnimation(.default){
                                            IsEmergencyView = true
                                        }
                                    }
                                }){
                                    ZStack(){
                                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                                            .fill(IsEmergencyView ? Color.blackBlue2 : Color.creamBlue)
                                            .frame(height: 85)
                                            .padding(.horizontal, 5)
                                        VStack{
                                            Text("紧")
                                                .bold()
                                                .foregroundStyle(IsEmergencyView ? Color.grayWhite1 : Color.blackBlue2)
                                            Text("急")
                                                .bold()
                                                .foregroundStyle(IsEmergencyView ? Color.grayWhite1 : Color.blackBlue2)
                                        }
                                        if EmergencyNum != 0{
                                            ZStack(){
                                                Circle()
                                                    .fill(Color.red)
                                                    .frame(width: 10, height: 10)
                                                    .shadow(color: Color.red, radius: 1)
                                                Text("\(EmergencyNum)")
                                                    .font(.system(size: 6))
                                                    .bold()
                                                    .foregroundStyle(Color.white)
                                            }
                                            .offset(x: 12, y: -28)
                                        }
                                    }
                                }
                                .padding(.bottom,-2)
                                Button(action: {
                                    if !isActionInProgress {
                                        isActionInProgress = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            isActionInProgress = false
                                        }
                                        IsTodoView = false
                                        IsEmergencyView = false
                                        IsSearchView = false
                                        IsSettingView = false
                                        IsStatisticsView = false
                                        withAnimation(.default){
                                            IsDoneView = true
                                        }
                                    }
                                }){
                                    ZStack{
                                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                                            .fill(IsDoneView ? Color.blackBlue2 : Color.creamBlue)
                                            .frame(height: 85)
                                            .padding(.horizontal, 5)
                                        VStack{
                                            Text("完")
                                                .bold()
                                                .foregroundStyle(IsDoneView ? Color.grayWhite1 : Color.blackBlue2)
                                            Text("成")
                                                .bold()
                                                .foregroundStyle(IsDoneView ? Color.grayWhite1 : Color.blackBlue2)
                                        }
                                    }
                                }
                                .padding(.bottom,-2)
                                Button(action: {
                                    if !isActionInProgress {
                                        isActionInProgress = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            isActionInProgress = false
                                        }
                                        IsDoneView = false
                                        IsTodoView = false
                                        IsEmergencyView = false
                                        IsSearchView = false
                                        IsSettingView = false
                                        withAnimation(.default){
                                            IsStatisticsView = true
                                        }
                                    }
                                }){
                                    ZStack{
                                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                                            .fill(IsStatisticsView ? Color.blackBlue2 : Color.creamBlue)
                                            .frame(height: 85)
                                            .padding(.horizontal, 5)
                                        VStack{
                                            Text("统")
                                                .bold()
                                                .foregroundStyle(IsStatisticsView ? Color.grayWhite1 : Color.blackBlue2)
                                            Text("计")
                                                .bold()
                                                .foregroundStyle(IsStatisticsView ? Color.grayWhite1 : Color.blackBlue2)
                                        }
                                    }
                                }
                                .padding(.vertical, -2)
                            }
                        }
                        .padding(.top)
                        VStack{
                            Spacer()
                            Text("\(getScore(tododata: tododata))")
                                .font(.system(size: 22))
                                .bold()
                                .foregroundStyle(Color.blackBlue2)
                                .frame(maxWidth: .infinity)
                                .popoverTip(scoreTip)
                                .onTapGesture{
                                    if #available(iOS 18.0, *) {
                                        Task { await ScoreTip.scoreEvent.donate() }
                                        Task { await ScoreTip.scoreEvent.donate()  }
                                    } else {
                                        Task { await ScoreTip.scoreEvent.donate()  }
                                    }
                                }
                        }
                        .padding(.bottom, 46)
                        .padding(5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }//左侧边栏
                    .frame(maxHeight: .infinity)
                    .frame(width: 50)
                    .background(Color.creamBlue)
                    VStack{//右主视图
                        ZStack(alignment: .bottom){
                            if IsTodoView {
                                TodoView(sort: sortOrder, AddTodoIsPresent: $AddTodoIsPresent, EmergencyNum: $EmergencyNum)
                            }
                            if IsEmergencyView {
                                EmergencyView(sort: sortOrder, AddTodoIsPresent: $AddTodoIsPresent, EmergencyNum: $EmergencyNum)
                            }
                            if IsDoneView {
                                DoneView(AddTodoIsPresent: $AddTodoIsPresent)
                            }
                            if IsSearchView {
                                SearchTodoView(sort: sortOrder, AddTodoIsPresent: $AddTodoIsPresent, EmergencyNum: $EmergencyNum)
                            }
                            if IsSettingView {
                                SettingView(reminder: $reminder, calendar: $calendar, selectedOptions: $selectedOptions)
                            }
                            if IsStatisticsView {
                                StatisticsView()
                            }
                            VStack{
                                if IsSettingView == false && IsStatisticsView == false && IsDoneView == false{
                                    HStack{
                                        Spacer()
                                        Menu("", systemImage: "arrow.up.arrow.down"){
                                            Picker("排序", selection: $sortOrder){
                                                Text("优先级")
                                                    .tag(SortDescriptor(\TodoData.priority))
                                                Text("添加日期")
                                                    .tag(SortDescriptor(\TodoData.addDate))
                                                Text("截止日期")
                                                    .tag(SortDescriptor(\TodoData.endDate))
                                                Text("开始日期")
                                                    .tag(SortDescriptor(\TodoData.startDoingDate))
                                            }
                                            .pickerStyle(.inline)
                                        }
                                        .bold()
                                        .accentColor(Color.myBlack)
                                        .padding(20)
                                        .padding(.top, 10)
                                    }
                                }
                                Spacer()
                                HStack{
                                    Spacer()
                                    Button(action: {
                                        AddTodoIsPresent = true
                                        addTaskTip.invalidate(reason: .actionPerformed)
                                    }){
                                        ZStack{
                                            Circle()
                                                .fill(Color.blackBlue2)
                                                .frame(width: 70, height: 70)
                                                .shadow(color: Color.blackBlue2,radius: 50)
                                            Image(systemName: "plus")
                                                .bold()
                                                .font(.system(size: 25))
                                                .foregroundColor(Color.grayWhite1)
                                        }
                                        .padding()
                                        .padding(.horizontal)
                                        .onAppear{
                                            if #available(iOS 18.0, *) {
                                                Task { await AddContentTip.presentEvent.donate() }
                                                Task { await AddContentTip.presentEvent.donate() }
                                            } else {
                                                Task { await AddContentTip.presentEvent.donate() }
                                            }
                                        }
                                    }
                                    .padding(.bottom)
                                }
                            }
                        }
                    }//右主视图
                    .frame(maxHeight: .infinity)
                    .frame(width: geo.size.width-50)
                    .background(Color.grayWhite1)
                    .offset(x: -8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("添加任务")
                                .fullScreenCover(isPresented: $AddTodoIsPresent, content: {// 模态跳转
                                    AddTodoView(AddTodoIsPresent: $AddTodoIsPresent,isActionInProgress: $isActionInProgress ,addtodo: TodoData(content: "", repeatTime: 0,priority: 1, endDate: tomorrowDate, addDate: Date(), doneDate: Date(),emergencyDate: Date(timeIntervalSince1970: tomorrowDate.timeIntervalSince1970 - TimeInterval(60*60*2*2)), startDoingDate: Date(), leftTime: 0,needTime: 2*60*60, actualFinishTime: 0, lastTime: 0, initialNeedTime: 0, Day: 0, Hour: 0, Min: 0, Sec: 0, todo: true, done: false, emergency: false, doing: false, offset: 0,lastoffset: 0, score: 0, times: 0))
                                })
            }
            if IsSettingView {
                VStack{
                    Spacer()
                    Text("鄂ICP备2024036893号-1A")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.blackGray)
                        .padding()
                }
            }
        }
        .onChange(of: store.purchasedCourses) { oldValue, newValue in
            Task {
                //TODO: FIX
                var hasPurchase1 = false
                var hasPurchase2 = false
                var hasPurchase3 = false
                var hasPurchase4 = false
                if store.storeProducts.count >= 1{
                    hasPurchase1 = (try? await store.isPurchased(store.storeProducts[0])) ?? false
                }
                if store.storeProducts.count >= 2{
                    hasPurchase2 = (try? await store.isPurchased(store.storeProducts[1])) ?? false
                }
                if store.storeProducts.count >= 3{
                    hasPurchase3 = (try? await store.isPurchased(store.storeProducts[2])) ?? false
                }
                if store.storeProducts.count >= 4{
                    hasPurchase4 = (try? await store.isPurchased(store.storeProducts[3])) ?? false
                }
                if hasPurchase1 || hasPurchase2 || hasPurchase3 || hasPurchase4 {
                    store.hasPurchased = true
                }
                if userSetting.count == 0 {
                    let setting = UserSetting(frequency: 1, reminder: reminder, hasPurchased: false, calendar: calendar, selectedOptions: selectedOptions)
                    modelContext.insert(setting)
                }else{
                    if store.hasPurchased{
                        reminder = userSetting[0].reminder
                        calendar = userSetting[0].calendar
                        userSetting[0].hasPurchased = true

                    }else{
                        userSetting[0].reminder = false
                        userSetting[0].calendar = false
                        userSetting[0].hasPurchased = false
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isActionInProgress = false
            }
            if userSetting.count == 0 {
                let setting = UserSetting(frequency: 1, reminder: reminder, hasPurchased: false, calendar: calendar, selectedOptions: selectedOptions)
                modelContext.insert(setting)
            }else{
                selectedOptions = []
                selectedOptions = userSetting[0].selectedOptions
            }
            getEmergencyNum(tododata: tododata)
            requestPermissions()
            requestAccessForReminders()
            requestCalendarPermission()
        }
    }
    
    func getEmergencyNum(tododata: [TodoData]){
        EmergencyNum = 0
        for todo in tododata {
            if todo.emergency {
                EmergencyNum += 1
            }
        }
    }
    
    func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("通知请求成功")
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    func requestAccessForReminders() {
        let eventStore = EKEventStore()
        let status = EKEventStore.authorizationStatus(for: .reminder)
        switch status {
            case .notDetermined:
                func handleRequestCompletion(success: Bool, error: Error?) {
                    if let error {
                        print("Error trying to request access: \(error)")
                    } else if success {
                        print("User granted access")
                    } else {
                        print("User denied access")
                    }
                }
            eventStore.requestFullAccessToReminders { success, error in
                handleRequestCompletion(success: success, error: error)
            }
            case .restricted:
                print("Restricted")
            case .denied:
                print("Denied") // Offer option to go to the app settings screen
            case .fullAccess, .authorized: // fullAccess is for iOS 17+. authorized is for iOS 16-
                print("Full access")
            case .writeOnly:
                print("Write-only access")
            @unknown default:
                print("Uh-oh, code is out-of-date")
        }
    }
    
    func requestCalendarPermission(){
        let eventStore = EKEventStore()
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
            case .notDetermined:
                func handleRequestCompletion(success: Bool, error: Error?) {
                    if let error {
                        print("Error trying to request access: \(error)")
                    } else if success {
                        print("User granted access")
                    } else {
                        print("User denied access")
                    }
                }
            eventStore.requestFullAccessToEvents { success, error in
                handleRequestCompletion(success: success, error: error)
            }
            case .restricted:
                print("Restricted")
            case .denied:
                print("Denied") // Offer option to go to the app settings screen
            case .fullAccess, .authorized:
                print("Full access")
            case .writeOnly:
                print("Write-only access")
            @unknown default:
                print("Uh-oh, code is out-of-date")
        }
    }
    
    func getScore(tododata: [TodoData]) -> Int {//计算效率分数
        var score: Int = 0
        var num: Int = 0
        let currentDate = Date()
        // 创建一个日历对象
        var calendar = Calendar.current
        // 获取本周的起始日期
        calendar.firstWeekday = 2
        if let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start {
            for todo in tododata{
                if todo.done && todo.doneDate.timeIntervalSince1970 > startOfWeek.timeIntervalSince1970 {
                    num += 1
                    score = todo.score + score
                }
            }
        } else {
            print("获取本周起始日期失败")
        }
//        for todo in tododata{
//            if todo.done && todo.doneDate.timeIntervalSince1970 > Date().timeIntervalSince1970 - TimeInterval(7*24*60*60){//近一周的
//                num += 1
//                score = todo.score + score
//            }
//        }
        if num != 0{
            return score/num
        }else{
            return 0
        }
    }
}
