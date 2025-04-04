//
//  SettingView.swift
//  DeadLineTodo
//
//  Created by Andy on 2024/1/27.
//

import SwiftUI
import SwiftData
import StoreKit
import EventKit

struct calendarData {
    var title: String
    var color: Color
}

struct SettingView: View {
    @Query var userSetting: [UserSetting] = []
    @Environment(\.modelContext) var modelContext
    @Environment(\.requestReview) var requestReview
    @EnvironmentObject var store: StoreKitManager
    
    @Binding var reminder: Bool
    @Binding var calendar: Bool
    @State var isStorePresent: Bool = false
    @State var isPurchaseAlert: Bool = false
    @State var calendarList: [calendarData] = []
    @Binding var selectedOptions: [String]

    func getCalendar() -> [calendarData]{
        let eventStore = EKEventStore()
        let calendars = eventStore.calendars(for: .event)
        var list: [calendarData] = []
        for calendar in calendars {
            list.append(calendarData(title: calendar.title, color: Color(cgColor: calendar.cgColor)))
        }
        return list
    }
    
    private func binding(for option: String) -> Binding<Bool> {
      Binding(
          get: { self.selectedOptions.contains(option) },
          set: { isSelected in
              if isSelected {
                  self.selectedOptions.append(option)
              } else {
                  self.selectedOptions.removeAll { $0 == option }
              }
          }
      )
  }
    
    var body: some View {
        VStack{
            HStack{
                Text("设置")
                    .font(.system(size: 30))
                    .bold()
                    .padding(20)
                    .foregroundStyle(Color.myBlack)
                Spacer()
            }
            ScrollView{
                VStack{
                    Button(action: {
                        requestReview()
                    }){
                        VStack{
                            HStack{
                                Text("给DeadLineTodo进行评分")
                                    .bold()
                                    .foregroundStyle(Color.myBlack)
                                Spacer()
                                Image(systemName: "star.fill")
                                    .bold()
                                    .foregroundStyle(Color.myBlack)
                                    .padding(.horizontal, 10)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                            HStack{
                                Text("欢迎在App Store反馈评价")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.blackGray)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, -3)
                        }
                    }
                    HStack{
                        Text("提醒事项同步")
                            .bold()
                            .foregroundStyle(Color.myBlack)
                        Spacer()
                        Toggle("", isOn: $reminder)
                                        .toggleStyle(SwitchToggleStyle(tint: .creamBlue))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    HStack{
                        Text("日历同步")
                            .bold()
                            .foregroundStyle(Color.myBlack)
                        Spacer()
                        Toggle("", isOn: $calendar)
                                        .toggleStyle(SwitchToggleStyle(tint: .creamBlue))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    if calendar {
                        //选择日历同步
                        VStack(spacing: 10) {
                            ForEach(calendarList.indices, id: \.self) { index in
                                HStack{
                                    Circle()
                                        .fill(calendarList[index].color)
                                        .frame(width: 10, height: 10)
                                    Toggle(calendarList[index].title, isOn: self.binding(for: calendarList[index].title))
                                        .foregroundStyle(Color.myBlack)
                                        .toggleStyle(SwitchToggleStyle(tint: .creamBlue))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                    HStack{
                        Button(action:{
                            isStorePresent = true
                        }){
                            Text("获取高级功能")
                                .bold()
                                .foregroundStyle(Color.myBlack)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    Spacer()
                }
                .padding(.bottom, 150)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .fullScreenCover(isPresented: $isStorePresent, content: {// 模态跳转
                StoreView(isStorePresent: $isStorePresent)
            })
        }
        .alert(isPresented: $isPurchaseAlert) {
            Alert(title: Text("提醒"), message: Text("购买高级功能解锁所有服务"), dismissButton: .default(Text("确定")){
                isPurchaseAlert = false
                isStorePresent = true
            })
        }
        .onChange(of: reminder) { oldVlue, newValue in
            if store.hasPurchased{
                userSetting[0].reminder = newValue
            }else{
                reminder = false
                isPurchaseAlert = true
            }
        }
        .onChange(of: calendar) { oldVlue, newValue in
            if store.hasPurchased{
                userSetting[0].calendar = newValue
            }else{
                calendar = false
                isPurchaseAlert = true
            }
        }
        .onChange(of: selectedOptions) { oldVlue, newValue in
            userSetting[0].selectedOptions = newValue
        }
        .onAppear {
            calendarList = getCalendar()
        }
    }
}
