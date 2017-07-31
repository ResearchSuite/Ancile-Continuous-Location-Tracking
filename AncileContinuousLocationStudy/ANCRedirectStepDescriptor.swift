//
//  ANCRedirectStepDescriptor.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 7/17/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

import ResearchSuiteTaskBuilder
import Gloss

open class ANCRedirectStepDescriptor: RSTBStepDescriptor {
    
    public let buttonText: String
    
    // MARK: - Deserialization
    
    required public init?(json: JSON) {
        
        guard let buttonText: String = "buttonText" <~~ json else {
            return nil
        }
        
        self.buttonText = buttonText
        
        super.init(json: json)
        
    }

}
