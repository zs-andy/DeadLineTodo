//
//  SettingsView.swift
//  DeadLineTodo
//
//  Settings view
//

import SwiftUI
import SwiftData
import StoreKit
import EventKit

struct SettingsView: View {
    
    @Query private var userSettings: [UserSetting] = []
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @EnvironmentObject private var store: StoreKitManager
    
    @Binding var reminder: Bool
    @Binding var calendar: Bool
    @Binding var selectedOptions: [String]
    
    @State private var isStorePresent = false
    @State private var isPurchaseAlert = false
    @State private var calendarList: [(title: String, color: Color)] = []
    
    var body: some View {
        VStack {
            HStack {
                Text(LocalizedStringKey("设置"))
                    .font(.system(size: 30))
                    .bold()
                    .padding(20)
                    .foregroundStyle(Color.myBlack)
                Spacer()
            }
            
            ScrollView {
                VStack {
                    // 评分按钮
                    rateButton
                    
                    // 提醒事项同步
                    toggleRow(title: "提醒事项同步", isOn: $reminder)
                    
                    // 日历同步
                    toggleRow(title: "日历同步", isOn: $calendar)
                    
                    // 日历选择
                    if calendar {
                        calendarSelection
                    }
                    
                    // 高级功能
                    premiumButton
                    
                    Spacer()
                }
                .padding(.bottom, 150)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .fullScreenCover(isPresented: $isStorePresent) {
            StoreView(isPresented: $isStorePresent)
        }
        .alert(Text("提醒"), isPresented: $isPurchaseAlert) {
            Button("确定") {
                isPurchaseAlert = false
                isStorePresent = true
            }
        } message: {
            Text("购买高级功能解锁所有服务")
        }
        .onChange(of: reminder) { _, newValue in handleReminderChange(newValue) }
        .onChange(of: calendar) { _, newValue in handleCalendarChange(newValue) }
        .onChange(of: selectedOptions) { _, newValue in
            if !userSettings.isEmpty { userSettings[0].selectedOptions = newValue }
        }
        .onAppear { loadCalendars() }
    }

    // MARK: - Subviews
    
    private var rateButton: some View {
        Button { requestReview() } label: {
            VStack {
                HStack {
                    Text(LocalizedStringKey("给DeadLineTodo进行评分"))
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
                
                HStack {
                    Text(LocalizedStringKey("欢迎在App Store反馈评价"))
                        .font(.system(size: 10))
                        .foregroundStyle(Color.blackGray)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, -3)
            }
        }
    }
    
    private func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(LocalizedStringKey(title))
                .bold()
                .foregroundStyle(Color.myBlack)
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle(tint: .creamBlue))
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var calendarSelection: some View {
        VStack(spacing: 10) {
            ForEach(calendarList.indices, id: \.self) { index in
                HStack {
                    Circle()
                        .fill(calendarList[index].color)
                        .frame(width: 10, height: 10)
                    Toggle(calendarList[index].title, isOn: binding(for: calendarList[index].title))
                        .foregroundStyle(Color.myBlack)
                        .toggleStyle(SwitchToggleStyle(tint: .creamBlue))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var premiumButton: some View {
        HStack {
            Button { isStorePresent = true } label: {
                Text(LocalizedStringKey("获取高级功能"))
                    .bold()
                    .foregroundStyle(Color.myBlack)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Helper Methods
    
    private func binding(for option: String) -> Binding<Bool> {
        Binding(
            get: { selectedOptions.contains(option) },
            set: { isSelected in
                if isSelected {
                    selectedOptions.append(option)
                } else {
                    selectedOptions.removeAll { $0 == option }
                }
            }
        )
    }
    
    private func loadCalendars() {
        let calendars = CalendarService.shared.getCalendars()
        calendarList = calendars.map { (title: $0.title, color: Color(cgColor: $0.color)) }
    }
    
    private func handleReminderChange(_ newValue: Bool) {
        if store.hasPurchased {
            if !userSettings.isEmpty { userSettings[0].reminder = newValue }
        } else {
            reminder = false
            isPurchaseAlert = true
        }
    }
    
    private func handleCalendarChange(_ newValue: Bool) {
        if store.hasPurchased {
            if !userSettings.isEmpty { userSettings[0].calendar = newValue }
        } else {
            calendar = false
            isPurchaseAlert = true
        }
    }
}
