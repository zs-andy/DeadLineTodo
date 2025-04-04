//
//  DeadLineTodoApp.swift
//  DeadLineTodo
//
//  Created by Andy on 2024/1/17.
//

import SwiftUI
@preconcurrency import SwiftData
import TipKit

typealias TodoData =  TodoDataSchemaV9.TodoData
typealias UserSetting = TodoDataSchemaV9.UserSetting

enum TodoDataMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] {
        [TodoDataSchemaV1.self, TodoDataSchemaV2.self, TodoDataSchemaV3.self, TodoDataSchemaV4.self, TodoDataSchemaV5.self, TodoDataSchemaV6.self, TodoDataSchemaV7.self, TodoDataSchemaV8.self, TodoDataSchemaV9.self]
    }
    static var stages: [MigrationStage]{
        [migrationV1toV2, migrationV2toV3, migrationV3toV4, migrationV4toV5, migrationV5toV6, migrationV6toV7, migrationV7toV8, migrationV8toV9]
    }
    static let migrationV1toV2 = MigrationStage.lightweight(fromVersion: TodoDataSchemaV1.self, toVersion: TodoDataSchemaV2.self)
    static let migrationV2toV3 = MigrationStage.lightweight(fromVersion: TodoDataSchemaV2.self, toVersion: TodoDataSchemaV3.self)
    static let migrationV3toV4 = MigrationStage.lightweight(fromVersion: TodoDataSchemaV3.self, toVersion: TodoDataSchemaV4.self)
    static let migrationV4toV5 = MigrationStage.lightweight(fromVersion: TodoDataSchemaV4.self, toVersion: TodoDataSchemaV5.self)
    static let migrationV5toV6 = MigrationStage.lightweight(fromVersion: TodoDataSchemaV5.self, toVersion: TodoDataSchemaV6.self)
    static let migrationV6toV7 = MigrationStage.lightweight(fromVersion: TodoDataSchemaV6.self, toVersion: TodoDataSchemaV7.self)
    static let migrationV7toV8 = MigrationStage.lightweight(fromVersion: TodoDataSchemaV7.self, toVersion: TodoDataSchemaV8.self)
    static let migrationV8toV9 = MigrationStage.lightweight(fromVersion: TodoDataSchemaV8.self, toVersion: TodoDataSchemaV9.self)
}


@main
struct DeadLineTodoApp: App {
    let container: ModelContainer
    
    @StateObject var store = StoreKitManager()
    
    @State var updated: Bool = false
    
    init() {
        do {
            //try Tips.resetDatastore()
            try Tips.configure()
            let config = ModelConfiguration("TodoData", schema: Schema([TodoData.self, UserSetting.self]))
            container = try ModelContainer(
                for: TodoData.self, UserSetting.self,
                migrationPlan: TodoDataMigrationPlan.self,
                configurations: config)
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
