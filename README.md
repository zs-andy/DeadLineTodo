<div align="center">

# DeadLineTodo

**A deadline-first task manager for iOS — built with SwiftUI, SwiftData, WidgetKit, and EventKit.**

[![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-0A84FF.svg)](#requirements)
[![Swift](https://img.shields.io/badge/Swift-SwiftUI%20%7C%20SwiftData-F05138.svg)](#tech-stack)
[![App Store](https://img.shields.io/badge/App%20Store-DeadLineTodo-111827.svg)](#overview)
[![Localization](https://img.shields.io/badge/i18n-EN%20%7C%20简中%20%7C%20繁中-10B981.svg)](#features)

**English** | [简体中文](README.zh-CN.md)

</div>

---

## Overview

**DeadLineTodo** (available on the iOS App Store under the same name) focuses on **time awareness** rather than endless checklists. Every task emphasizes how much time remains through visual progress indicators, urgency views, system calendar/reminder sync, home-screen widgets, and completion statistics.

## Features

- **Deadline-first task cards**: Visual time progress bars, urgency sorting (`EmergencyView`), search, and archive (`DoneView`).
- **Home Screen Widgets**: Native `WidgetKit` extension (`DeadLineTodoWidget`) keeping upcoming deadlines visible at a glance.
- **Apple Calendar & Reminders Sync**: Two-way `EventKit` integration (`CalendarService`, `ReminderService`) plus scheduled `UserNotifications`.
- **Productivity Insights**: Built-in `Swift Charts` analytics and a GitHub-style completion heatmap (`ContributionChartView`).
- **Schema-safe persistence**: `SwiftData` with an explicit 9-version `SchemaMigrationPlan` (`TodoDataSchemaV1` → `V9`) for safe upgrades.
- **Native polish**: `StoreKit 2` in-app store, `TipKit` onboarding hints, and full localization in English, Simplified Chinese, and Traditional Chinese.

## Tech Stack

| Layer | Technologies |
| --- | --- |
| UI & Architecture | SwiftUI, MVVM, TipKit |
| Persistence | SwiftData (`VersionedSchema` V1–V9, lightweight migrations) |
| System Integration | WidgetKit, EventKit (Calendar & Reminders), UserNotifications |
| Analytics & Commerce | Swift Charts, StoreKit 2 |
| Dependencies | SwiftUIPullToRefresh |

## Project Structure

```text
DeadLineTodo/
├── DeadLineTodoApp.swift            # App entry & SwiftData V1–V9 migration plan
├── Models/
│   ├── TodoData.swift               # Current SwiftData schema (V9)
│   ├── ChartData.swift              # Statistics & heatmap models
│   └── LegacySchemas.swift          # Historical schemas (V1–V8)
├── Views/
│   ├── Main/                        # ContentView, SidebarView
│   ├── Todo/                        # TodoList, TodoCard, Add/Edit, Emergency, Done, Search
│   ├── Statistics/                  # StatisticsView, ContributionChartView
│   ├── Settings/                    # Calendar/Reminders sync & preferences
│   └── Store/                       # StoreKit 2 StoreView
├── Utilities/                       # TodoService, Calendar/Reminder/Notification/StoreKit managers
├── Localize/                        # en.lproj, zh-Hans.lproj, zh-Hant.lproj
└── DeadLineTodoWidget/              # WidgetKit extension
```

## Requirements & Running Locally

- **Xcode 15.2+** (Xcode 16+ recommended)
- **iOS 17.0+** simulator or physical device

```sh
git clone https://github.com/zs-andy/DeadLineTodo.git
open DeadLineTodo/DeadLineTodo.xcodeproj
```

1. Select the `DeadLineTodo` scheme in Xcode.
2. Update the signing team under **Signing & Capabilities** if building for a physical device.
3. For StoreKit testing in Simulator, choose `DeadLineTodoStore.storekit` in your scheme's Run Options.
4. Press **⌘R** to build and run.

## Contributing

Bug reports, UX ideas, localization improvements, and pull requests are welcome! Great areas to help with:

- **Localization**: Adding new languages or refining copy in `DeadLineTodo/Localize/`.
- **Widgets & Live Activities**: New `WidgetKit` layouts or lock-screen widgets.
- **Accessibility**: VoiceOver labels, Dynamic Type scaling, and contrast refinements.
- **Tests**: Unit tests for `TodoService` and SwiftData migrations.

Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a PR.
