//
//  ContributionChartView.swift
//  DeadLineTodo
//
//  GitHub-style contribution heat map chart
//

import SwiftUI

struct ContributionChartView: View {
    
    let data: [Double]
    let rows: Int
    let columns: Int
    let targetValue: Double
    var blockColor: Color = .green
    var blockBackgroundColor: Color = Color.grayWhite1
    var rectangleWidth: Double = 19.0
    var rectangleSpacing: Double = 2.0
    var rectangleRadius: Double = 6.0
    
    var body: some View {
        HStack(spacing: rectangleSpacing) {
            // Week day labels
            VStack(spacing: rectangleSpacing) {
                ForEach(weekNumbers, id: \.self) { day in
                    Text("\(day)")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .frame(height: rectangleWidth)
                }
            }
            .padding(.trailing, 4)
            
            // Heat map grid
            ForEach(0..<columns, id: \.self) { col in
                let start = col * rows
                let end = min((col + 1) * rows, data.count)
                let columnData = Array(data[start..<end])
                
                ContributionColumnView(
                    rowData: columnData,
                    rows: rows,
                    targetValue: targetValue,
                    blockColor: blockColor,
                    blockBackgroundColor: blockBackgroundColor,
                    rectangleWidth: rectangleWidth,
                    rectangleSpacing: rectangleSpacing,
                    rectangleRadius: rectangleRadius
                )
            }
        }
    }
    
    private var weekNumbers: [Int] {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (0..<7).map { (weekday + $0 - 1) % 7 + 1 }
    }
}

// MARK: - Column View

private struct ContributionColumnView: View {
    
    let rowData: [Double]
    let rows: Int
    let targetValue: Double
    let blockColor: Color
    let blockBackgroundColor: Color
    let rectangleWidth: Double
    let rectangleSpacing: Double
    let rectangleRadius: Double
    
    var body: some View {
        VStack(spacing: rectangleSpacing) {
            ForEach(0..<rows, id: \.self) { index in
                ZStack {
                    RoundedRectangle(cornerRadius: rectangleRadius)
                        .frame(width: rectangleWidth, height: rectangleWidth)
                        .foregroundColor(blockBackgroundColor)
                    
                    if index < rowData.count {
                        RoundedRectangle(cornerRadius: rectangleRadius)
                            .frame(width: rectangleWidth, height: rectangleWidth)
                            .foregroundColor(blockColor.opacity(opacityRatio(for: index)))
                    }
                }
            }
        }
    }
    
    private func opacityRatio(for index: Int) -> Double {
        guard index < rowData.count, targetValue > 0 else { return 0 }
        return min(rowData[index] / targetValue, 1.0)
    }
}
