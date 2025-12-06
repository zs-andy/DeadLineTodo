# DeadLineTodo

**中文** | [English](README_EN.md)

---

## 项目简介

DeadLineTodo 是一款智能任务管理 iOS 应用，专注于时间感知和效率提升。通过可视化进度条、紧急提醒和效率统计，帮助用户更好地管理任务截止时间，提高工作效率。

---

## 技术栈

- **框架**: SwiftUI + SwiftData
- **架构**: MVVM
- **通知**: UserNotifications + EventKit
- **内购**: StoreKit 2
- **图表**: Swift Charts
- **提示**: TipKit
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

## 数据模型

### TodoData

```swift
@Model
final class TodoData: Identifiable {
    var id = UUID()
    
    // 内容和优先级
    var content: String = ""
    var priority: Int = 0
    var repeatTime: Int = 0
    
    // 时间管理
    var endDate: Date = Date()
    var emergencyDate: Date = Date()
    var needTime: TimeInterval = 0
    var actualFinishTime: TimeInterval = 0
    
    // 状态标记
    var todo: Bool = false
    var done: Bool = false
    var emergency: Bool = false
    var doing: Bool = false
    
    // 效率评分
    var score: Int = 100
    var times: Int = 0
}
```

### UserSetting

```swift
@Model
final class UserSetting: Identifiable {
    var frequency: Int = 1
    var reminder: Bool = true
    var hasPurchased: Bool = false
    var calendar: Bool = false
    var selectedOptions: [String] = []
}
```

**数据迁移**
- 支持从 V1 到 V9 的无缝升级
- 轻量级迁移策略，保证数据完整性
- 向后兼容，支持旧版本数据

---

## 核心功能

### 1. 智能任务管理（TodoListView）
- 可视化进度条显示任务紧急程度
- 实时时间计算和状态更新
- 滑动操作（删除、开始/暂停、完成）
- 多维度排序（优先级、时间、状态）

### 2. 时间感知系统（TodoService）
- 动态计算剩余时间和紧急状态
- 智能进度条宽度计算
- 效率分数算法（时间分数 30% + 效率分数 70%）
- 重复任务自动生成

### 3. 多平台同步（Services）
- **通知集成**: 截止提醒、紧急通知、超时警告
- **日历同步**: 自动创建日历事件，支持多日历选择
- **提醒事项**: 与系统提醒事项双向同步

### 4. 效率统计（StatisticsView）
- GitHub 风格热力图显示完成情况
- 多时间维度图表（周/月/年）
- 工作时长统计和时间差异分析
- 周效率分数计算
- 骨架屏加载动画，流畅的用户体验

### 5. 高级功能（内购）
- 重复任务功能
- 完整统计分析
- 提醒事项和日历同步
- 所有后续更新功能

---

## 性能优化

### 统计页面优化策略

1. **桶排序算法优化**
   - 将 O(n×m) 的嵌套循环优化为 O(n+m)
   - 预先按天/月分组数据到桶中，避免重复遍历
   - 单次遍历完成所有时间段的数据聚合

2. **智能加载控制**
   - 使用 `hasLoaded` 标志避免重复加载
   - 基于列数变化（而非宽度变化）触发热力图重载
   - 屏幕旋转时仅重新计算热力图数据

3. **后台线程计算**
   - 所有数据计算在 `DispatchQueue.global(qos: .userInitiated)` 执行
   - 预过滤已完成任务，减少后续计算量
   - 计算完成后批量更新 UI，减少重绘次数

4. **骨架屏加载动画**
   - 渐变动画的骨架屏占位符
   - 平滑的淡入淡出过渡效果
   - 提升用户等待时的视觉体验

---
