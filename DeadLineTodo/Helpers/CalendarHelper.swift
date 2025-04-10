//
//  CalendarHelper.swift
//  DeadLineTodo
//
//  Created by Haiyao Zhou on 09/04/2025.
//

import Foundation

class CalendarHelper {
    private let reminderService = ReminderService()
    private let calendarService = CalendarService()
    
    func updateCalendar(_ calendarId: inout Int, _ calendar2Id: inout Int) {
        calendarId += 1
        calendar2Id += 1
    }
    
    func handleCalendarEvent(
        userSetting: [UserSetting],
        title: String,
        edittodo: TodoData
    ) {
        if userSetting[0].calendar {
            calendarService.editEventInCalendar(
                oldTitle: title,
                newTitle: edittodo.content,
                startDate: edittodo.emergencyDate,
                dueDate: Date(timeIntervalSince1970: edittodo.emergencyDate.timeIntervalSince1970 + TimeInterval(edittodo.Day * 86400 + edittodo.Hour * 3600 + edittodo.Min * 60))
            )
        } else {
            calendarService.deleteEventFromCalendar(title: title)
        }
    }
}

