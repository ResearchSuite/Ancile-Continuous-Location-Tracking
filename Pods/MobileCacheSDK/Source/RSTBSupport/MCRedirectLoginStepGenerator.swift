//
//  MCRedirectLoginStepGenerator.swift
//  Pods
//
//  Created by James Kizer on 7/29/17.
//
//

import ResearchSuiteTaskBuilder
import ResearchKit
import Gloss
import ResearchSuiteExtensions

open class MCRedirectLoginStepGenerator: RSRedirectStepGenerator {
    let _supportedTypes = [
        "MCRedirectLogin"
    ]
    
    open override var supportedTypes: [String]! {
        return self._supportedTypes
    }
    
    open override func getDelegate(helper: RSTBTaskBuilderHelper) -> RSRedirectStepDelegate? {
        
        guard let provider = helper.stateHelper as? MCManagerProvider else {
                return nil
        }
        
        return provider.getManager()
    }
    
}
