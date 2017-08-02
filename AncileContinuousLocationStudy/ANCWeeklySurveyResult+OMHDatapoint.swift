//
//  ANCWeeklySurveyResult+OMHDatapoint.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 7/20/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

import OMHClient

extension ANCWeeklySurveyResult: OMHDataPointBuilder {
    
    open var creationDateTime: Date {
        return self.startDate ?? Date()
    }
    
    open var dataPointID: String {
        return self.uuid.uuidString
    }
    
    open var acquisitionModality: OMHAcquisitionProvenanceModality? {
        return .SelfReported
    }
    
    open var acquisitionSourceCreationDateTime: Date? {
        return self.startDate
    }
    
    open var acquisitionSourceName: String? {
        return Bundle.main.infoDictionary![kCFBundleNameKey as String] as? String
    }
    
    open var schema: OMHSchema {
        return OMHSchema(name: "ancile-phone-spec-weekly-survey", version: "1.0", namespace: "cornell")
    }
    
    open var body: [String: Any] {
        var returnBody: [String: Any] = [:]
        
        returnBody["days_on_campus"] = self.daysOnCampus
        returnBody["travel_plans"] = self.travelPlans
        
        return returnBody
        
    }

}
