//
//  DistanceSample.swift
//  AncileContinuousLocationStudy
//
//  Created by James Kizer on 10/27/17.
//  Copyright © 2017 Cornell Tech. All rights reserved.
//

import OMHClient
import ResearchSuiteResultsProcessor

open class DistanceSample: RSRPIntermediateResult {
    
    let sampleDescription: String
    let distance: Double
    let creationDate: Date
    
    public init(
        uuid: UUID,
        taskIdentifier: String,
        taskRunUUID: UUID,
        sampleDescription: String,
        distance: Double
        ) {
        self.sampleDescription = sampleDescription
        self.distance = distance
        self.creationDate = Date()
        
        super.init(
            type: "DistanceSample",
            uuid: uuid,
            taskIdentifier: taskIdentifier,
            taskRunUUID: taskRunUUID
        )
        
    }

}

extension DistanceSample: OMHDataPointBuilder {
    open var schema: OMHSchema {
        return OMHSchema(
            name: "distance",
            version: "1.0",
            namespace: "cornell")
    }
    
    open var creationDateTime: Date {
        return self.creationDate
    }
    
    open var dataPointID: String {
        return self.uuid.uuidString
    }
    
    open var acquisitionModality: OMHAcquisitionProvenanceModality? {
        return .SelfReported
    }
    
    open var acquisitionSourceCreationDateTime: Date? {
        return self.creationDate
    }
    
    open var acquisitionSourceName: String? {
        return Bundle.main.infoDictionary![kCFBundleNameKey as String] as? String
    }
    
    open var body: [String: Any] {
        return [
            "distance": self.distance,
            "description": self.sampleDescription,
            "effective_time_frame": [
                "date_time": self.stringFromDate(self.creationDateTime)
            ]
        ]
    }
}

