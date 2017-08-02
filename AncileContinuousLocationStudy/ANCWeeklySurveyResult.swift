//
//  ANCWeeklySurveyResult.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 7/20/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

import UIKit
import ResearchKit
import ResearchSuiteResultsProcessor
import Gloss
import OMHClient

open class ANCWeeklySurveyResult: RSRPIntermediateResult, RSRPFrontEndTransformer {
    
    private static let supportedTypes = [
        "WeeklySurvey"
    ]
    
    public static func supportsType(type: String) -> Bool {
        return self.supportedTypes.contains(type)
    }
    
    
    public static func transform(taskIdentifier: String, taskRunUUID: UUID, parameters: [String : AnyObject]) -> RSRPIntermediateResult? {
        
        let travelPlans: String? = {
            guard let stepResult = parameters["travel_plans"],
                let result = stepResult.firstResult as? ORKTextQuestionResult,
                let travelPlans = result.textAnswer else {
                    return nil
            }
            return travelPlans
        }()
        
        let daysOnCampus: [String]? = {
            guard let stepResult = parameters["days_on_campus"],
                let result = stepResult.firstResult as? ORKChoiceQuestionResult,
                let choices = result.choiceAnswers as? [String] else {
                    return nil
            }
            return choices
        }()
        
        let weekly = ANCWeeklySurveyResult(
            uuid: UUID(),
            taskIdentifier: taskIdentifier,
            taskRunUUID: taskRunUUID,
            daysOnCampus: daysOnCampus,
            travelPlans: travelPlans)
        
        weekly.startDate = parameters["days_on_campus"]?.startDate ?? Date()
        weekly.endDate = parameters["travel_plans"]?.endDate ?? Date()
        
        return weekly
        
    }
    
    public let travelPlans: String?
    public let daysOnCampus: [String]?
    
    public init(
        uuid: UUID,
        taskIdentifier: String,
        taskRunUUID: UUID,
        daysOnCampus: [String]?,
        travelPlans: String?
        ) {
        
        self.travelPlans = travelPlans
        self.daysOnCampus = daysOnCampus
        
        super.init(
            type: "WeeklyStatus",
            uuid: uuid,
            taskIdentifier: taskIdentifier,
            taskRunUUID: taskRunUUID
        )
    }
    
}
