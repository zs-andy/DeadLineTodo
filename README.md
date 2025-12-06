# DeadLineTodo

**中文** | [English](README_EN.md)

---

## 项目简介

DeadLineTodo 是一款智能任务管理 iOS 应用，专注于时间感知和效率提升。通过可视化进度条、紧急提醒和效率统计，帮助用户更好地管理任务截止时间，提高工作效率。

---

## 技术栈

- **UI 框架**: SwiftUI
- **数据持久化**: SwiftData
- **架构模式**: MVVM
- **系统集成**: UserNotifications, EventKit, WidgetKit
- **内购系统**: StoreKit 2
- **数据可视化**: Swift Charts
- **用户引导**: TipKit
- **第三方库**: SwiftUIPullToRefresh
- **最低版本**: iOS 17.0+

---

## 项目结构

```
DeadLineTodo/
├── Models/                    # 数据模型层
│   ├── TodoData.swift        # 任务数据模型 (V9)
│   ├── ChartData.swift       # 图表数据模型
│   └── LegacySchemas.swift   # 历史版本模型 (V1-V8)
├── Views/                     # 视图层
│   ├── Main/                 # 主界面
│   │   ├── ContentView.swift
│   │   └── SidebarView.swift
│   ├── Todo/                 # 任务管理
│   │   ├── TodoListView.swift
│   │   ├── TodoCardView.swift
│   │   ├── AddTodoView.swift
│   │   ├── EditTodoView.swift
│   │   ├── EmergencyView.swift
│   │   ├── DoneView.swift
│   │   └── SearchTodoView.swift
│   ├── Statistics/           # 统计分析
│   │   ├── StatisticsView.swift
│   │   └── ContributionChartView.swift
│   ├── Settings/             # 设置
│   │   └── SettingsView.swift
│   └── Store/                # 内购商店
│       └── StoreView.swift
├── Utilities/                 # 工具类
│   ├── TodoService.swift     # 核心业务逻辑
│   ├── NotificationService.swift
│   ├── CalendarService.swift
│   ├── ReminderService.swift
│   ├── StoreKitManager.swift
│   ├── Extensions.swift
│   └── AppTips.swift
├── Localize/                  # 多语言支持
│   ├── en.lproj/
│   ├── zh-Hans.lproj/
│   └── zh-Hant.lproj/
└── DeadLineTodoApp.swift     # 应用入口
```

---