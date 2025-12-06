//
//  ChartData.swift
//  DeadLineTodo
//
//  Chart data models for statistics
//

import Foundation

// MARK: - Line Chart Data

struct LineWeekData: Identifiable {
    let day: String
    var value: Int
    let id = UUID()
}

struct LineMonthData: Identifiable {
    let day: String
    var value: Int
    let id = UUID()
}

struct LineYearData: Identifiable {
    let month: String
    var value: Int
    let id = UUID()
}

// MARK: - Working Time Data

struct WorkingTimeWeekData: Identifiable {
    let day: String
    var value: Double
    var range: String
    let id = UUID()
}

struct WorkingTimeMonthData: Identifiable {
    let day: String
    var value: Double
    var range: String
    let id = UUID()
}

struct WorkingTimeYearData: Identifiable {
    let month: String
    var value: Double
    var range: String
    let id = UUID()
}

// MARK: - Time Difference Data

struct TimeDifferenceWeekData: Identifiable {
    let day: String
    var value: Double
    var range: String
    let id = UUID()
}

struct TimeDifferenceMonthData: Identifiable {
    let day: String
    var value: Double
    var range: String
    let id = UUID()
}

struct TimeDifferenceYearData: Identifiable {
    let month: String
    var value: Double
    var range: String
    let id = UUID()
}

// MARK: - Calendar Data

struct CalendarData {
    let title: String
    let color: Color
}

import SwiftUI

// MARK: - Legacy Type Aliases (for Widget compatibility)

typealias lineWeekData = LineWeekData
typealias lineMonthData = LineMonthData
typealias lineYearData = LineYearData
typealias workingTimeWeekData = WorkingTimeWeekData
typealias workingTimeMonthData = WorkingTimeMonthData
typealias workingTimeYearData = WorkingTimeYearData
typealias timeDiferenceWeekData = TimeDifferenceWeekData
typealias timeDiferenceMonthData = TimeDifferenceMonthData
typealias timeDiferenceYearData = TimeDifferenceYearData
typealias calendarData = CalendarData
