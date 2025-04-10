//
//  EditTodoView.swift
//  DeadLineTodo
//
//  Created by Andy on 2024/1/24.
//

import SwiftUI
import SwiftData
import EventKit

struct EditTodoView: View {
    @Binding var EditTodoIsPresent: Bool
    @Environment(\.modelContext) var modelContext
    
    @State private var calendarId: Int = 0
    @State private var calendar2Id: Int = 0
    
    @State var priority:[String] = ["无","高","中","低"]
    @State var selectedPriority: Int = 0
    @State var selectedCycle: Int = 0
    @State var cycle:[String] = ["无","天","周","月"]
    @State var edittodo: TodoData
    
    @State private var title:String = ""
    @State private var day: Int = 0
    @State private var hour: Int = 0
    @State private var min: Int = 0
    @State private var needTIme: TimeInterval = 0
    @State private var emergencyDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var priorityInt: Int = 0
    @State private var repeatTime: Int = 0
    
    @State var cancelTime: Int = 0
    
    @State private var showAlert = false
    @State private var showAlertEndTime = false
    @State private var showAlertEmergencyTime = false
    @State private var showAlertNeedTime = false
    

    var body: some View {
        ZStack{
            VStack(){
                EditTodoHeaderView(edittodo: $edittodo, cancelTime: $cancelTime, EditTodoIsPresent: $EditTodoIsPresent, selectedPriority: $selectedPriority)
                EditTodoBodyView(edittodo: $edittodo, calendar2Id: $calendar2Id, calendarId: $calendarId, EditTodoIsPresent: $EditTodoIsPresent, selectedPriority: $selectedPriority, selectedCycle: $selectedCycle)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.grayWhite1)
    }
}

