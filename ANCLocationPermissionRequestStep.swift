//
//  ANCLocationPermissionRequestStep.swift
//  AncileContinuousLocationStudy
//
//  Created by James Kizer on 10/27/17.
//  Copyright © 2017 Christina Tsangouri. All rights reserved.
//

import UIKit
import ResearchKit

class ANCLocationPermissionRequestStep: ORKStep {
    let buttonText: String
    
    public init(identifier: String,
                title: String? = nil,
                text: String? = nil,
                buttonText: String? = nil) {
        
        let title = title ?? "We Need Permissions"
        let text = text ?? "We need permission to access your location"
        self.buttonText = buttonText ?? "Grant Permission"
        
        super.init(identifier: identifier)
        
        self.title = title
        self.text = text
        
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func stepViewControllerClass() -> AnyClass {
        return ANCLocationPermissionRequestStepViewController.self
    }
}
