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
        
//        returnBody["sleep_1"] = self.sleep_1
//        returnBody["sleep_2"] = self.sleep_2
        returnBody["sleep_3"] = self.sleep_3
        returnBody["food_1"] = self.food_1
        returnBody["food_2"] = self.food_2
        returnBody["food_3"] = self.food_3
        returnBody["food_4"] = self.food_4
        returnBody["commute_1"] = self.commute_1
        returnBody["commute_2"] = self.commute_2
        returnBody["commute_3"] = self.commute_3
        returnBody["commute_4"] = self.commute_4
        
//        returnBody["days_on_campus"] = self.daysOnCampus
//        returnBody["travel_plans"] = self.travelPlans
        
        return returnBody
        
    }

}
