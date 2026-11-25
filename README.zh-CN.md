<div align="center">

# DeadLineTodo

**专注截止时间感知的 iOS 待办应用 — 基于 SwiftUI、SwiftData、WidgetKit 与 EventKit。**

[![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-0A84FF.svg)](#运行环境与本地构建)
[![Swift](https://img.shields.io/badge/Swift-SwiftUI%20%7C%20SwiftData-F05138.svg)](#技术栈)
[![App Store](https://img.shields.io/badge/App%20Store-DeadLineTodo-111827.svg)](#项目简介)
[![Localization](https://img.shields.io/badge/i18n-EN%20%7C%20简中%20%7C%20繁中-10B981.svg)](#核心特性)

[English](README.md) | **简体中文**

</div>

---

## 项目简介

**DeadLineTodo**（App Store 同名上架）是一款围绕 **Deadline 时间感知** 设计的 iOS 任务管理应用。相比传统待办清单，它通过直观的时间进度条、紧急视图、系统日历/提醒事项同步、桌面小组件与效率统计，帮你始终看清真正紧迫的事情。

## 核心特性

- **时间感知卡片**：可视化截止进度条与时间刻度，支持紧急模式（`EmergencyView`）、搜索与归档（`DoneView`）。
- **桌面小组件**：原生 `WidgetKit` 扩展（`DeadLineTodoWidget`），在主屏幕随时查看近期 DDL。
- **日历与提醒事项同步**：集成 `EventKit`（`CalendarService`、`ReminderService`）与本地推送通知（`UserNotifications`）。
- **效率统计与热力图**：基于 `Swift Charts` 的统计视图与类似 GitHub 风格的完成热力图（`ContributionChartView`）。
- **平滑数据迁移**：基于 `SwiftData` 的 9 版本 `SchemaMigrationPlan`（`V1` → `V9`），保障版本升级不丢数据。
- **多语言与原生体验**：集成 `StoreKit 2` 内购、`TipKit` 新手引导，支持简体中文、繁体中文与英文。

## 技术栈

| 模块 | 技术选型 |
| --- | --- |
| UI 与架构 | SwiftUI、MVVM、TipKit |
| 数据持久化 | SwiftData（`VersionedSchema` V1–V9 轻量级迁移） |
| 系统集成 | WidgetKit、EventKit（日历 / 提醒事项）、UserNotifications |
| 可视化与商业化 | Swift Charts、StoreKit 2 |
| 第三方依赖 | SwiftUIPullToRefresh |

## 项目结构

```text
DeadLineTodo/
├── DeadLineTodoApp.swift            # 应用入口与 SwiftData V1–V9 迁移计划
├── Models/
│   ├── TodoData.swift               # 当前数据模型 (V9)
│   ├── ChartData.swift              # 统计与热力图模型
│   └── LegacySchemas.swift          # 历史 Schema (V1–V8)
├── Views/
│   ├── Main/                        # ContentView、SidebarView
│   ├── Todo/                        # 列表、卡片、增改、紧急视图、已完成、搜索
│   ├── Statistics/                  # 效率统计与贡献热力图
│   ├── Settings/                    # 同步设置与偏好
│   └── Store/                       # StoreKit 2 内购页
├── Utilities/                       # 核心业务与日历/提醒/通知/内购服务
├── Localize/                        # en.lproj、zh-Hans.lproj、zh-Hant.lproj
└── DeadLineTodoWidget/              # WidgetKit 桌面小组件扩展
```

## 运行环境与本地构建

- **Xcode 15.2+**（推荐 Xcode 16+）
- **iOS 17.0+** 模拟器或真机

```sh
git clone https://github.com/zs-andy/DeadLineTodo.git
open DeadLineTodo/DeadLineTodo.xcodeproj
```

1. 在 Xcode 中选择 `DeadLineTodo` scheme。
2. 如需真机运行，在 **Signing & Capabilities** 中切换为你自己的开发者 Team。
3. 在模拟器测试内购时，可在 Scheme 的 Run Options 中绑定 `DeadLineTodoStore.storekit`。
4. 按 **⌘R** 编译运行。

## 参与贡献

欢迎提交 Issue、设计建议、多语言翻译或 Pull Request！非常欢迎以下方向的贡献：

- **多语言本地化**：在 `DeadLineTodo/Localize/` 中补充新语言或润色现有文案。
- **小组件与交互**：新增 `WidgetKit` 尺寸布局或锁屏小组件。
- **无障碍适配**：VoiceOver 标签、动态字体（Dynamic Type）与对比度优化。
- **单元测试**：补充 `TodoService` 与 `SwiftData` 迁移测试。

提交前请先阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。
