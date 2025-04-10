//
//  ReminderHelper.swift
//  DeadLineTodo
//
//  Created by Haiyao Zhou on 09/04/2025.
//

import Foundation

class ReminderHelper {
    
    let reminderService = ReminderService()
    let calendarService = CalendarService()
    
    func handleReminders(
           userSetting: [UserSetting],
           title: String,
           selectedPriority: Int,
           edittodo: inout TodoData,
       ) {
           if userSetting[0].reminder {
               reminderService.editEventToReminders(
                   title: title,
                   priority: selectedPriority,
                   editTo: edittodo.content,
                   dueDate: edittodo.emergencyDate,
                   remindDate: edittodo.emergencyDate,
                   edittodo: edittodo
               )
           } else {
               reminderService.removeEventToReminders(title: title)
               edittodo.priority = [0, 1, 5, 9][min(selectedPriority, 3)]
           }
       }
}
