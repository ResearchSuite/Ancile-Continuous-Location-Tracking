//
//  ANCAuthStepGenerator.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 7/17/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

import UIKit
import ResearchSuiteTaskBuilder
import ResearchKit
import Gloss

open class ANCAuthStepGenerator: RSTBBaseStepGenerator {
    
    public init(){}
    
    open var supportedTypes: [String]! {
        return nil
    }
    
    open func getDelegate(ancileClient: AncileStudyServerClient) -> ANCRedirectStepDelegate! {
        return nil
    }
    
    open func generateStep(type: String, jsonObject: JSON, helper: RSTBTaskBuilderHelper) -> ORKStep? {
        
        guard let stepDescriptor = ANCRedirectStepDescriptor(json:jsonObject),
            let ancileClientProvider = helper.stateHelper as? AncileClientProvider,
            let ancileClient = ancileClientProvider.getAncileClient() else {
                return nil
        }
        
        let step = ANCRedirectStep(
            identifier: stepDescriptor.identifier,
            title: stepDescriptor.title,
            text: stepDescriptor.text,
            buttonText: stepDescriptor.buttonText,
            delegate: self.getDelegate(ancileClient: ancileClient)
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

open class ANCAncileAuthStepGenerator: ANCAuthStepGenerator {
    let _supportedTypes = [
        "AncileAuth"
    ]
    
    open override var supportedTypes: [String]! {
        return self._supportedTypes
    }
    
    open override func getDelegate(ancileClient: AncileStudyServerClient) -> ANCRedirectStepDelegate! {
        return ancileClient.ancileAuthDelegate
    }

}

open class ANCCoreAuthStepGenerator: ANCAuthStepGenerator {
    let _supportedTypes = [
        "CoreAuth"
    ]
    
    open override var supportedTypes: [String]! {
        return self._supportedTypes
    }
    
    open override func getDelegate(ancileClient: AncileStudyServerClient) -> ANCRedirectStepDelegate! {
        return ancileClient.coreAuthDelegate
    }
    
}
