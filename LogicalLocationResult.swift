//
//  LogicalLocationResult.swift
//  AncileContinuousLocationStudy
//
//  Created by James Kizer on 10/22/17.
//  Copyright © 2017 Cornell Tech. All rights reserved.
//

import OMHClient
import ResearchSuiteResultsProcessor

open class LogicalLocationResult: RSRPIntermediateResult {
    public enum Action: String {
        case enter = "enter"
        case exit = "exit"
        case startedInside = "startedInside"
        case startedOutside = "startedOutside"
        case startedUnknown = "startedUnknown"
    }
    
    public let locationName: String
    public let action: Action
    public let eventTimestamp: Date
    
    public init(
        uuid: UUID,
        taskIdentifier: String,
        taskRunUUID: UUID,
        locationName: String,
        action: Action,
        eventTimestamp: Date
        ) {
        self.locationName = locationName
        self.action = action
        self.eventTimestamp = eventTimestamp
        
        super.init(
            type: "LogicalLocationResult",
            uuid: uuid,
            taskIdentifier: taskIdentifier,
            taskRunUUID: taskRunUUID
        )
        
    }
    
}

extension LogicalLocationResult: OMHDataPointBuilder {
    open var schema: OMHSchema {
        return OMHSchema(
            name: "logical-location",
            version: "1.0",
            namespace: "cornell")
    }
    
    open var creationDateTime: Date {
        return self.eventTimestamp
    }
    
    open var dataPointID: String {
        return self.uuid.uuidString
    }
    
    open var acquisitionModality: OMHAcquisitionProvenanceModality? {
        return .SelfReported
    }
    
    open var acquisitionSourceCreationDateTime: Date? {
        return self.eventTimestamp
    }
    
    open var acquisitionSourceName: String? {
        return Bundle.main.infoDictionary![kCFBundleNameKey as String] as? String
    }
    
    open var body: [String: Any] {
        return [
            "location": self.locationName,
            "action": self.action.rawValue,
            "effective_time_frame": [
                "date_time": self.stringFromDate(self.creationDateTime)
            ]
        ]
    }
    
}
