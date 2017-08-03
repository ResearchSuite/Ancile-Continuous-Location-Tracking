//
//  ANCDailySurveyResult.swift
//  AncileContinuousLocationStudy
//
//  Created by Christina Tsangouri on 8/2/17.
//  Copyright © 2017 Christina Tsangouri. All rights reserved.
//

import UIKit
import ResearchKit
import ResearchSuiteResultsProcessor
import Gloss
import OMHClient

//
//  ANCDailySurveyResult.swift
//  AncileContinuousLocationStudy
//
//  Created by Christina Tsangouri on 8/2/17.
//  Copyright © 2017 Christina Tsangouri. All rights reserved.
//
//

import UIKit
import ResearchKit
import ResearchSuiteResultsProcessor
import Gloss
import OMHClient

open class ANCDailySurveyResult: RSRPIntermediateResult, RSRPFrontEndTransformer {
    
    private static let supportedTypes = [
        "DailySurvey"
    ]
    
    public static func supportsType(type: String) -> Bool {
        return self.supportedTypes.contains(type)
    }
    
    
    public static func transform(taskIdentifier: String, taskRunUUID: UUID, parameters: [String : AnyObject]) -> RSRPIntermediateResult? {
        
        let sleep_1: String? = {
            guard let stepResult = parameters["sleep_1"],
                let result = stepResult.firstResult as? ORKTimeOfDayQuestionResult,
                let timeOfDay = result.dateComponentsAnswer else {
                    return nil
            }
            
            let timeOfDayString = String(describing: timeOfDay)
            
            return timeOfDayString
        }()
        
        
        let sleep_2: String? = {
            guard let stepResult = parameters["sleep_2"],
                let result = stepResult.firstResult as? ORKTimeOfDayQuestionResult,
                let timeOfDay = result.dateComponentsAnswer else {
                    return nil
            }
            let timeOfDayString = String(describing: timeOfDay)
            
            return timeOfDayString
        }()
        
        
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
        
        let commute_3: NSNumber? = {
            guard let stepResult = parameters["commute_3"],
                let result = stepResult.firstResult as? ORKScaleQuestionResult,
                let scale = result.scaleAnswer else {
                    return nil
            }
            return scale
        }()
        
        let commute_4: NSNumber? = {
            guard let stepResult = parameters["commute_4"],
                let result = stepResult.firstResult as? ORKScaleQuestionResult,
                let scale = result.scaleAnswer else {
                    return nil
            }
            return scale
        }()
        
        
        let commute_5: [String]? = {
            guard let stepResult = parameters["commute_5"],
                let result = stepResult.firstResult as? ORKChoiceQuestionResult,
                let choices = result.choiceAnswers as? [String] else {
                    return nil
            }
            return choices
        }()
        
        
        let daily = ANCDailySurveyResult(
            uuid: UUID(),
            taskIdentifier: taskIdentifier,
            taskRunUUID: taskRunUUID,
            sleep_1: sleep_1,
            sleep_2: sleep_2,
            sleep_3: sleep_3,
            food_1: food_1,
            food_2: food_2,
            food_3: food_3,
            food_4: food_4,
            commute_1: commute_1,
            commute_2: commute_2,
            commute_3: commute_3,
            commute_4: commute_4,
            commute_5: commute_5)
        
            daily.startDate = parameters["sleep_1"]?.startDate ?? Date()
            daily.endDate = parameters["commute_5"]?.endDate ?? Date()
        //
        return daily
        
    }
    
    public let sleep_1: String?
    public let sleep_2: String?
    public let sleep_3: [String]?
    public let food_1: [String]?
    public let food_2: [String]?
    public let food_3: [String]?
    public let food_4: [String]?
    public let commute_1: [String]?
    public let commute_2: [String]?
    public let commute_3: NSNumber?
    public let commute_4: NSNumber?
    public let commute_5: [String]?
    
    public init(
        uuid: UUID,
        taskIdentifier: String,
        taskRunUUID: UUID,
        sleep_1: String?,
        sleep_2: String?,
        sleep_3: [String]?,
        food_1: [String]?,
        food_2: [String]?,
        food_3: [String]?,
        food_4: [String]?,
        commute_1: [String]?,
        commute_2: [String]?,
        commute_3: NSNumber?,
        commute_4: NSNumber?,
        commute_5: [String]?
        ) {
        
        
        self.sleep_1 = sleep_1
        self.sleep_2 = sleep_2
        self.sleep_3 = sleep_3
        self.food_1 = food_1
        self.food_2 = food_2
        self.food_3 = food_3
        self.food_4 = food_4
        self.commute_1 = commute_1
        self.commute_2 = commute_2
        self.commute_3 = commute_3
        self.commute_4 = commute_4
        self.commute_5 = commute_5
        
        
        super.init(
            type: "DailyStatus",
            uuid: uuid,
            taskIdentifier: taskIdentifier,
            taskRunUUID: taskRunUUID
        )
    }
    
}


