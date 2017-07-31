//
//  ANCRedirectStep.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 7/13/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

import UIKit
import ResearchKit

open class ANCRedirectStep: ORKStep {
    
    let delegate: ANCRedirectStepDelegate
    let buttonText: String
    
    public init(identifier: String,
                title: String? = nil,
                text: String? = nil,
                buttonText: String? = nil,
                delegate: ANCRedirectStepDelegate) {
        
        let title = title ?? "Log in"
        let text = text ?? "Please log in"
        self.buttonText = buttonText ?? "Log In"
        self.delegate = delegate
        
        super.init(identifier: identifier)
        
        self.title = title
        self.text = text
        
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func instantiateStepViewController(with result: ORKResult) -> ORKStepViewController {
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: ANCRedirectStep.self))
        let vc = storyboard.instantiateViewController(withIdentifier: "ANCRedirectStepViewController") as! ANCRedirectStepViewController
        
        vc.configure(with: self, result: result)
        return vc
    }
    
    

}
