//
//  ANCRedirectStepDelegate.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 7/13/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

import UIKit

public protocol ANCRedirectStepDelegate: ANCOpenURLDelegate {
    
    func redirectViewControllerDidLoad(viewController: ANCRedirectStepViewController)
    
    //this is used by the delegate to open the redirect URL
    //note that the delegate should store the completion handler 
    func beginRedirect(completion: @escaping ((Error?) -> ()))
    
}


