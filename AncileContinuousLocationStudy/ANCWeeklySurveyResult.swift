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
        
//        let travelPlans: String? = {
//            guard let stepResult = parameters["travel_plans"],
//                let result = stepResult.firstResult as? ORKTextQuestionResult,
//                let travelPlans = result.textAnswer else {
//                    return nil
//            }
//            return travelPlans
//        }()
        
        // Continuous Location Tracking Question results transform
        
        //not sure how to tranform date answer

        // this is wrong return must be date not string
//        let sleep_1: [String]? = {
//            guard let stepResult = parameters["sleep_1"],
//                let result = stepResult.firstResult as? ORKChoiceQuestionResult,
//                let choices = result.choiceAnswers as? [String] else {
//                    return nil
//            }
//            return choices
//        }()
//        
        
//        let sleep_2: DateComponents = {
//            guard let stepResult = parameters["sleep_2"],
//                let result = stepResult.firstResult as? ORKTimeOfDayQuestionResult,
//                let dateComponents = result.dateComponentsAnswer
//                else {
//                    return nil
//            }
//            return dateComponents
//        }()
        
        let sleep_3: [String]? = {
            guard let stepResult = parameters["sleep_3"],
                let result = stepResult.firstResult as? ORKChoiceQuestionResult,
                let choices = result.choiceAnswers as? [String] else {
                    return nil
            }
            return choices
        }()
        
        
    
        let food_1: [String]? = {
            guard let stepResult = parameters["food_1"],
                let result = stepResult.firstResult as? ORKChoiceQuestionResult,
                let choices = result.choiceAnswers as? [String] else {
                    return nil
            }
            return choices
        }()
        
        let food_2: [String]? = {
            guard let stepResult = parameters["food_2"],
                let result = stepResult.firstResult as? ORKChoiceQuestionResult,
                let choices = result.choiceAnswers as? [String] else {
                    return nil
            }
            return choices
        }()
        
        let food_3: [String]? = {
            guard let stepResult = parameters["food_3"],
                let result = stepResult.firstResult as? ORKChoiceQuestionResult,
                let choices = result.choiceAnswers as? [String] else {
                    return nil
            }
            return choices
        }()
        
        let food_4: [String]? = {
            guard let stepResult = parameters["food_4"],
                let result = stepResult.firstResult as? ORKChoiceQuestionResult,
                let choices = result.choiceAnswers as? [String] else {
                    return nil
            }
            return choices
        }()
        
        let commute_1: [String]? = {
            guard let stepResult = parameters["commute_1"],
                let result = stepResult.firstResult as? ORKChoiceQuestionResult,
                let choices = result.choiceAnswers as? [String] else {
                    return nil
            }
            return choices
        }()
        
        
        let commute_2: [String]? = {
            guard let stepResult = parameters["commute_2"],
                let result = stepResult.firstResult as? ORKChoiceQuestionResult,
                let choices = result.choiceAnswers as? [String] else {
                    return nil
            }
            return choices
        }()
        
        let commute_3: [String]? = {
            guard let stepResult = parameters["commute_3"],
                let result = stepResult.firstResult as? ORKChoiceQuestionResult,
                let choices = result.choiceAnswers as? [String] else {
                    return nil
            }
            return choices
        }()
        
        let commute_4: [String]? = {
            guard let stepResult = parameters["commute_4"],
                let result = stepResult.firstResult as? ORKChoiceQuestionResult,
                let choices = result.choiceAnswers as? [String] else {
                    return nil
            }
            return choices
        }()
        
        
        
//        let daysOnCampus: [String]? = {
//            guard let stepResult = parameters["days_on_campus"],
//                let result = stepResult.firstResult as? ORKChoiceQuestionResult,
//                let choices = result.choiceAnswers as? [String] else {
//                    return nil
//            }
//            return choices
//        }()
        
        let weekly = ANCWeeklySurveyResult(
            uuid: UUID(),
            taskIdentifier: taskIdentifier,
            taskRunUUID: taskRunUUID,
            sleep_3: sleep_3,
            food_1: food_1,
            food_2: food_2,
            food_3: food_3,
            food_4: food_4,
            commute_1: commute_1,
            commute_2: commute_2,
            commute_3: commute_3,
            commute_4: commute_4)
//            daysOnCampus: daysOnCampus,
//            travelPlans: travelPlans)
        
        weekly.startDate = parameters["days_on_campus"]?.startDate ?? Date()
        weekly.endDate = parameters["travel_plans"]?.endDate ?? Date()
        
        return weekly
        
    }
    
//    public let travelPlans: String?
//    public let daysOnCampus: [String]?
    
 //   public let sleep_1:
 //   public let sleep_2:
    
    public let sleep_3: [String]?
    public let food_1:  [String]?
    public let food_2:  [String]?
    public let food_3:  [String]?
    public let food_4:  [String]?
    public let commute_1:  [String]?
    public let commute_2:  [String]?
    public let commute_3:  [String]?
    public let commute_4:  [String]?
    
    
    public init(
        uuid: UUID,
        taskIdentifier: String,
        taskRunUUID: UUID,
//        sleep_1: String?,
//        sleep_2: String?,
        sleep_3: [String]?,
        food_1: [String]?,
        food_2: [String]?,
        food_3: [String]?,
        food_4: [String]?,
        commute_1: [String]?,
        commute_2: [String]?,
        commute_3: [String]?,
        commute_4: [String]?
//        daysOnCampus: [String]?,
//        travelPlans: String?
        ) {
        
//        self.travelPlans = travelPlans
//        self.daysOnCampus = daysOnCampus
//        
        
        self.sleep_3 = sleep_3
        self.food_1 = food_1
        self.food_2 = food_2
        self.food_3 = food_3
        self.food_4 = food_4
        self.commute_1 = commute_1
        self.commute_2 = commute_2
        self.commute_3 = commute_3
        self.commute_4 = commute_4
        
        super.init(
            type: "WeeklyStatus",
            uuid: uuid,
            taskIdentifier: taskIdentifier,
            taskRunUUID: taskRunUUID
        )
    }
    
}
