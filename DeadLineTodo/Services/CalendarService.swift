//
//  CalendarService.swift
//  DeadLineTodo
//
//  Created by Haiyao Zhou on 09/04/2025.
//

import Foundation
import EventKit

class CalendarService {
    private let eventStore = EKEventStore()
    
    func addEventToCalendar(title: String, startDate: Date, dueDate: Date) {        
        let newEvent = EKEvent(eventStore: eventStore)
        newEvent.title = title
        newEvent.calendar = eventStore.defaultCalendarForNewEvents
        
        newEvent.startDate = startDate
        newEvent.endDate = dueDate
        
        let alarm = EKAlarm(absoluteDate: startDate)
        newEvent.addAlarm(alarm)
        
        print("add")
        
        do {
            try eventStore.save(newEvent, span: .thisEvent)
            print("Event saved successfully")
        } catch let error {
            print("Event failed with error: \(error.localizedDescription)")
        }
    }
    
    func editEventInCalendar(oldTitle: String, newTitle: String, startDate: Date, dueDate: Date) {
        let eventStore = EKEventStore()
        let predicate = eventStore.predicateForEvents(withStart: Date(), end: Date().addingTimeInterval(31 * 24 * 60 * 60), calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        for event in events {
            if event.title == oldTitle {
                event.title = newTitle
                
                event.startDate = startDate
                event.endDate = dueDate
                
                if let alarms = event.alarms {
                    for alarm in alarms {
                        event.removeAlarm(alarm)
                    }
                }
                
                let alarm = EKAlarm(absoluteDate: startDate)
                event.addAlarm(alarm)
                
                do {
                    try eventStore.save(event, span: .thisEvent)
                    print("事件修改成功")
                    return
                } catch {
                    print("事件修改失败: \(error.localizedDescription)")
                    return
                }
            }
        }
        addEventToCalendar(title: newTitle,startDate: startDate, dueDate: dueDate)
    }
}
