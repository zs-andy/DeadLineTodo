//
//  SidebarView.swift
//  DeadLineTodo
//
//  Navigation sidebar component
//

import SwiftUI
import TipKit

struct SidebarView: View {
    
    @Binding var currentView: ContentView.ViewType
    let emergencyNum: Int
    let weeklyScore: Int
    let scoreTip: ScoreTip
    
    @State private var isActionInProgress = false
    
    var body: some View {
        VStack {
            // 导航按钮区域
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(Color.creamBlue)
                    .padding(.horizontal, 5)
                
                VStack {
                    // 设置按钮 - 无防抖
                    Button {
                        withAnimation(.default) {
                            currentView = .settings
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(currentView == .settings ? Color.blackBlue2 : Color.creamBlue)
                                .frame(height: 50)
                                .padding(.horizontal, 5)
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(currentView == .settings ? Color.grayWhite1 : Color.blackBlue2)
                        }
                    }
                    
                    // 搜索按钮
                    Button {
                        switchView(to: .search)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(currentView == .search ? Color.blackBlue2 : Color.creamBlue)
                                .frame(height: 50)
                                .padding(.horizontal, 5)
                            Image(systemName: "magnifyingglass")
                                .bold()
                                .foregroundStyle(currentView == .search ? Color.grayWhite1 : Color.blackBlue2)
                        }
                    }
                    
                    // 待办按钮
                    Button {
                        switchView(to: .todo)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(currentView == .todo ? Color.blackBlue2 : Color.creamBlue)
                                .frame(height: 70)
                                .padding(.horizontal, 5)
                            VStack(spacing: 4) {
                                Image(systemName: "list.bullet")
                                    .bold()
                                    .foregroundStyle(currentView == .todo ? Color.grayWhite1 : Color.blackBlue2)
                                Text(NSLocalizedString("sidebar.todo", comment: ""))
                                    .font(.system(size: 8))
                                    .bold()
                                    .foregroundStyle(currentView == .todo ? Color.grayWhite1 : Color.blackBlue2)
                            }
                        }
                    }
                    .padding(.bottom, -2)
                    
                    // 紧急按钮
                    Button {
                        switchView(to: .emergency)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(currentView == .emergency ? Color.blackBlue2 : Color.creamBlue)
                                .frame(height: 70)
                                .padding(.horizontal, 5)
                            VStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .foregroundStyle(currentView == .emergency ? Color.grayWhite1 : Color.blackBlue2)
                                Text(NSLocalizedString("sidebar.emergency", comment: ""))
                                    .font(.system(size: 8))
                                    .bold()
                                    .foregroundStyle(currentView == .emergency ? Color.grayWhite1 : Color.blackBlue2)
                            }
                            
                            if emergencyNum != 0 {
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 10, height: 10)
                                        .shadow(color: Color.red, radius: 1)
                                    Text("\(emergencyNum)")
                                        .font(.system(size: 6))
                                        .bold()
                                        .foregroundStyle(Color.white)
                                }
                                .offset(x: 12, y: -28)
                            }
                        }
                    }
                    .padding(.bottom, -2)
                    
                    // 完成按钮
                    Button {
                        switchView(to: .done)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(currentView == .done ? Color.blackBlue2 : Color.creamBlue)
                                .frame(height: 70)
                                .padding(.horizontal, 5)
                            VStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                    .bold()
                                    .foregroundStyle(currentView == .done ? Color.grayWhite1 : Color.blackBlue2)
                                Text(NSLocalizedString("sidebar.done", comment: ""))
                                    .font(.system(size: 8))
                                    .bold()
                                    .foregroundStyle(currentView == .done ? Color.grayWhite1 : Color.blackBlue2)
                            }
                        }
                    }
                    .padding(.bottom, -2)
                    
                    // 统计按钮
                    Button {
                        switchView(to: .statistics)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(currentView == .statistics ? Color.blackBlue2 : Color.creamBlue)
                                .frame(height: 70)
                                .padding(.horizontal, 5)
                            VStack(spacing: 4) {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundStyle(currentView == .statistics ? Color.grayWhite1 : Color.blackBlue2)
                                Text(NSLocalizedString("sidebar.statistics", comment: ""))
                                    .font(.system(size: 8))
                                    .bold()
                                    .foregroundStyle(currentView == .statistics ? Color.grayWhite1 : Color.blackBlue2)
                            }
                        }
                    }
                    .padding(.vertical, -2)
                }
            }
            .padding(.top)
            
            // 周效率分数
            VStack {
                Spacer()
                Text("\(weeklyScore)")
                    .font(.system(size: 22))
                    .bold()
                    .foregroundStyle(Color.blackBlue2)
                    .frame(maxWidth: .infinity)
                    .popoverTip(scoreTip)
                    .onTapGesture {
                        if #available(iOS 18.0, *) {
                            Task { await ScoreTip.scoreEvent.donate() }
                            Task { await ScoreTip.scoreEvent.donate() }
                        } else {
                            Task { await ScoreTip.scoreEvent.donate() }
                        }
                    }
            }
            .padding(.bottom, 46)
            .padding(5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxHeight: .infinity)
        .frame(width: 50)
        .background(Color.creamBlue)
    }
    
    // MARK: - Helper
    
    private func switchView(to type: ContentView.ViewType) {
        guard !isActionInProgress else { return }
        
        isActionInProgress = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isActionInProgress = false
        }
        
        withAnimation(.default) {
            currentView = type
        }
    }
}
