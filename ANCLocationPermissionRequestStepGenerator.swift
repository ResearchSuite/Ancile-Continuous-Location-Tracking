//
//  ANCLocationPermissionRequestStepGenerator.swift
//  AncileContinuousLocationStudy
//
//  Created by James Kizer on 10/27/17.
//  Copyright © 2017 Christina Tsangouri. All rights reserved.
//

import UIKit
import ResearchSuiteTaskBuilder
import ResearchKit
import Gloss

open class ANCLocationPermissionRequestStepDescriptor: RSTBStepDescriptor {
    
    public let buttonText: String
    
    required public init?(json: JSON) {
        guard let buttonText: String = "buttonText" <~~ json else {
            return nil
        }
        self.buttonText = buttonText
        super.init(json: json)
    }
    
}

open class ANCLocationPermissionRequestStepGenerator: RSTBBaseStepGenerator {
    
    public init(){}
    
    open var supportedTypes: [String]! {
        return ["locationPermissionRequest"]
    }
    
    open func generateStep(type: String, jsonObject: JSON, helper: RSTBTaskBuilderHelper) -> ORKStep? {
        
        guard let stepDescriptor = ANCLocationPermissionRequestStepDescriptor(json:jsonObject) else {
                return nil
        }
        
        let step = ANCLocationPermissionRequestStep(
            identifier: stepDescriptor.identifier,
            title: stepDescriptor.title,
            text: stepDescriptor.text,
            buttonText: stepDescriptor.buttonText
        )
        
        step.isOptional = stepDescriptor.optional
        
        return step
    }
    
    open func processStepResult(type: String,
                                jsonObject: JsonObject,
                                result: ORKStepResult,
                                helper: RSTBTaskBuilderHelper) -> JSON? {
        return nil
    }
    
}
