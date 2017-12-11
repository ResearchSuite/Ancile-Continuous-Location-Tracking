//
//  ANCLocationEventManager.swift
//  AncileContinuousLocationStudy
//
//  Created by James Kizer on 11/16/17.
//  Copyright © 2017 Christina Tsangouri. All rights reserved.
//

import UIKit
import ResearchSuiteResultsProcessor

class ANCLocationEventManager: NSObject {
    
    
    var events: [LocationEvent] = []
    
    let csvBackend: RSRPCSVBackEnd
    
    public init(csvBackend: RSRPCSVBackEnd) {
        
        self.csvBackend = csvBackend
        
        super.init()
//        if csvBackend.getFileURLForType(typeIdentifier: LocationEvent.typeString) == nil {
//            
//            //add events in bulk
//            do {
//                try csvBackend.add(csvRecords: self.generateEvents())
//            }
//            catch let error as NSError {
//                print(error)
//            }
//        }
        
    }
    
    //generate a bunch of sample data points
    //M-F, leave home at 8AM, arrive at work 8:45, leave work at 5:15, arrive home at 6
    //Weekend, lave home at 12, arrive home at 8
    
    //start date, 26 weeks ago
    
    func generateEvents() -> [LocationEvent] {
        
        let calendar = Calendar(identifier: .gregorian)
        let weeks:TimeInterval = 26
        let longTimeAgo = Date().addingTimeInterval(-weeks*7*24*60*60)
        
        let weekdays = 2...6
        let weekdayEvents: [(Int, Int?, String, LocationEventAction)] = [
            (8, nil, "home", .exit),
            (8, 45, "work", .enter),
            (17, 15, "work", .exit),
            (16, nil, "home", .enter)
        ]
        
        let weekdayDateCompentEvents: [(DateComponents, String, LocationEventAction)] = weekdays.flatMap({ (weekday) -> [(DateComponents, String, LocationEventAction)] in
            return weekdayEvents.map({ (weekdayEvent) -> (DateComponents, String, LocationEventAction) in
                let dateComponents = DateComponents(hour: weekdayEvent.0, minute: weekdayEvent.1, weekday: weekday)
                return (dateComponents, weekdayEvent.2, weekdayEvent.3)
            })
            
        })
        
        let weekendDays = [1, 7]
        let weekendEvents: [(Int, Int?, String, LocationEventAction)] = [
            (12, nil, "home", .exit),
            (20, nil, "home", .enter)
        ]
        
        let weekendDateCompentEvents: [(DateComponents, String, LocationEventAction)] = weekendDays.flatMap({ (day) -> [(DateComponents, String, LocationEventAction)] in
            return weekendEvents.map({ (event) -> (DateComponents, String, LocationEventAction) in
                let dateComponents = DateComponents(hour: event.0, minute: event.1, weekday: day)
                return (dateComponents, event.2, event.3)
            })
            
        })
        
        let locationEvents = [weekdayDateCompentEvents, weekendDateCompentEvents].joined().flatMap { (dateComponentEvent) -> [LocationEvent] in
            
            let (dateComponent, identifier, action) = dateComponentEvent
            var locationEvents: [LocationEvent] = []
            calendar.enumerateDates(startingAfter: longTimeAgo, matching: dateComponent, matchingPolicy: .strict) { (date, isExactMatch, shouldStop) in
                
                if let date = date,
                    date < Date() {
                    let locationEvent = LocationEvent(uuid: UUID(), identifier: identifier, action: action, timestamp: date)
                    locationEvents.append(locationEvent)
                }
                else {
                    shouldStop = true
                }
            }
            
            return locationEvents
            
            
            }.sorted { $0.timestamp < $1.timestamp }
        
        
        return locationEvents
    }
    
    public func runTests() {
        
        let events = self.generateEvents()
        let readCount = 10
        var addEventTimings: [AddEventTiming] = []
        var readEventTimings: [ReadEventTiming] = []
        
        //clear files
        self.csvBackend.removeFileForType(type: LocationEvent.self)
        self.csvBackend.removeFileForType(type: AddEventTiming.self)
        self.csvBackend.removeFileForType(type: ReadEventTiming.self)
        
        events.enumerated().forEach { (offset: Int, event: LocationEvent) in
            
            let startTime = Date()
            do {
                try csvBackend.add(encodable: event)
            }
            catch let error as NSError {
                print(error)
            }
            let endTime = Date()
            
            let duration = endTime.timeIntervalSince(startTime)
            addEventTimings.append(AddEventTiming(uuid: event.uuid, index: offset, duration: duration))
        }
        
        (0...readCount).forEach { (index) in
            
            let startTime = Date()
            do {
                let events = try csvBackend.getRecordsOfType(type: LocationEvent.self)
            }
            catch let error as NSError {
                print(error)
            }
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            readEventTimings.append(ReadEventTiming(index: index, duration: duration))
            
        }
        
        do {
            try self.csvBackend.add(csvRecords: addEventTimings)
            try self.csvBackend.add(csvRecords: readEventTimings)
        } catch let error as NSError {
            print(error)
        }
        

        debugPrint(self.csvBackend.getFileURLForType(typeIdentifier: AddEventTiming.typeString))
        debugPrint(self.csvBackend.getFileURLForType(typeIdentifier: ReadEventTiming.typeString))
        
    }

}
