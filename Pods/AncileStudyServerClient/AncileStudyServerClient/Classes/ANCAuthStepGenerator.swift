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
import ResearchSuiteExtensions

open class ANCAncileAuthStepGenerator: RSRedirectStepGenerator {
    let _supportedTypes = [
        "AncileAuth"
    ]
    
    open override var supportedTypes: [String]! {
        return self._supportedTypes
    }
    
    open override func getDelegate(helper: RSTBTaskBuilderHelper) -> RSRedirectStepDelegate! {
        
        guard let ancileClientProvider = helper.stateHelper as? ANCClientProvider,
            let ancileClient = ancileClientProvider.getAncileClient() else {
                return nil
        }
        
        return ancileClient.ancileAuthDelegate
    }

}

open class ANCCoreAuthStepGenerator: RSRedirectStepGenerator {
    let _supportedTypes = [
        "CoreAuth"
    ]
    
    open override var supportedTypes: [String]! {
        return self._supportedTypes
    }
    
    open override func getDelegate(helper: RSTBTaskBuilderHelper) -> RSRedirectStepDelegate! {
        guard let ancileClientProvider = helper.stateHelper as? ANCClientProvider,
            let ancileClient = ancileClientProvider.getAncileClient() else {
                return nil
        }
        
        return ancileClient.coreAuthDelegate
    }
    
}
