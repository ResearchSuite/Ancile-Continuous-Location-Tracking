//
//  ANCOhmageAuthDelegate.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 7/20/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

import UIKit

open class ANCOhmageAuthDelegate: NSObject, ANCRedirectStepDelegate, ANCOpenURLDelegate {
    
    private weak var client: AncileStudyServerClient!
    private var authCompletion: ((Error?) -> ())? = nil
    
    init(client: AncileStudyServerClient) {
        super.init()
        self.client = client
    }
    
    
    public func redirectViewControllerDidLoad(viewController: ANCRedirectStepViewController) {
        
    }
    
    public func beginRedirect(completion: @escaping ((Error?) -> ())) {
        
        guard let authToken = self.client.authToken else {
            return
        }
        
        self.authCompletion = completion
        
        self.client.getCoreLink(authToken: authToken) { (urlString, error) in
            
            debugPrint(urlString)
            if let err = error {
                debugPrint(err)
                self.authCompletion?(error)
                return
            }
            
            if let urlString = urlString,
                let url: URL = URL(string: urlString) {
                ANCOpenURLManager.safeOpenURL(url: url)
                return
            }
            else {
                self.authCompletion?(nil)
            }
            
        }
    }
    
    public func handleURL(url: URL) -> Bool {
        
        //check to see if this matches the expected format
        //ancile3ec3082ca348453caa716cc0ec41791e://auth/ancile/callback?code={CODE}
        let pattern = "^\(ANCOpenURLManager.URLScheme)://auth/ancile/confirm_core_auth"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        
        guard let _ = regex.firstMatch(
            in: url.absoluteString,
            options: .init(rawValue: 0),
            range: NSMakeRange(0, url.absoluteString.characters.count)) else {
                return false
        }
        
        if let successString = ANCOpenURLManager.getQueryStringParameter(url: url.absoluteString, param: "success") {
            
            self.authCompletion?(nil)
            return true
            
        }
        
        return false
    }

}
