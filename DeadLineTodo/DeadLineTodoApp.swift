//
//  DeadLineTodoApp.swift
//  DeadLineTodo
//
//  Created by Andy on 2024/1/17.
//  Refactored with modern Swift and MVVM architecture
//

import SwiftUI
@preconcurrency import SwiftData
import TipKit

// MARK: - Type Aliases

typealias TodoData = TodoDataSchemaV9.TodoData
typealias UserSetting = TodoDataSchemaV9.UserSetting

// MARK: - Migration Plan

enum TodoDataMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] {
        [
            TodoDataSchemaV1.self,
            TodoDataSchemaV2.self,
            TodoDataSchemaV3.self,
            TodoDataSchemaV4.self,
            TodoDataSchemaV5.self,
            TodoDataSchemaV6.self,
            TodoDataSchemaV7.self,
            TodoDataSchemaV8.self,
            TodoDataSchemaV9.self
        ]
    }
    
    static var stages: [MigrationStage] {
        [
            MigrationStage.lightweight(fromVersion: TodoDataSchemaV1.self, toVersion: TodoDataSchemaV2.self),
            MigrationStage.lightweight(fromVersion: TodoDataSchemaV2.self, toVersion: TodoDataSchemaV3.self),
            MigrationStage.lightweight(fromVersion: TodoDataSchemaV3.self, toVersion: TodoDataSchemaV4.self),
            MigrationStage.lightweight(fromVersion: TodoDataSchemaV4.self, toVersion: TodoDataSchemaV5.self),
            MigrationStage.lightweight(fromVersion: TodoDataSchemaV5.self, toVersion: TodoDataSchemaV6.self),
            MigrationStage.lightweight(fromVersion: TodoDataSchemaV6.self, toVersion: TodoDataSchemaV7.self),
            MigrationStage.lightweight(fromVersion: TodoDataSchemaV7.self, toVersion: TodoDataSchemaV8.self),
            MigrationStage.lightweight(fromVersion: TodoDataSchemaV8.self, toVersion: TodoDataSchemaV9.self)
        ]
    }
}

// MARK: - App Entry Point

@main
struct DeadLineTodoApp: App {
    
    let container: ModelContainer
    @StateObject private var store = StoreKitManager()
    @State private var updated = false
    
    init() {
        do {
            try Tips.configure()
            
            let config = ModelConfiguration(
                "TodoData",
                schema: Schema([TodoData.self, UserSetting.self])
            )
            
            container = try ModelContainer(
                for: TodoData.self, UserSetting.self,
                migrationPlan: TodoDataMigrationPlan.self,
                configurations: config
            )
        } catch {
            print("初始化模型容器时发生错误：\(error)")
            fatalError("Failed to initialize model container.")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(updated: $updated)
                .environmentObject(store)
        }
        .modelContainer(container)
    }
}
