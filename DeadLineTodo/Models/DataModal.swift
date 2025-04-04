//
//  DataModal.swift
//  DeadLineTodo
//
//  Created by Andy on 2024/1/19.
//

import Foundation
import SwiftData

struct lineWeekData:Identifiable {
    var day: String
    var value: Int
    var id = UUID()
}

struct lineMonthData:Identifiable {
    var day: String
    var value: Int
    var id = UUID()
}

struct lineYearData: Identifiable{
    var month: String
    var value: Int
    var id = UUID()
}

struct workingTimeWeekData: Identifiable{
    var day: String
    var value: Double
    var range: String
    var id = UUID()
}

struct workingTimeMonthData: Identifiable{
    var day: String
    var value: Double
    var range: String
    var id = UUID()
}

struct workingTimeYearData: Identifiable{
    var month: String
    var value: Double
    var range: String
    var id = UUID()
}

struct timeDiferenceWeekData: Identifiable{
    var day: String
    var value: Double
    var range: String
    var id = UUID()
}

struct timeDiferenceMonthData: Identifiable{
    var day: String
    var value: Double
    var range: String
    var id = UUID()
}

struct timeDiferenceYearData: Identifiable{
    var month: String
    var value: Double
    var range: String
    var id = UUID()
}
