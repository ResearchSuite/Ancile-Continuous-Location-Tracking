//
//  ANCAncileAuthDelegate.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 7/17/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

import UIKit

//this class handles Ancile Study Server Auth
//In beginRedirect, we save a reference to the closure, then open the url for auth
//in handle url, extract 
public class ANCAncileAuthDelegate: NSObject, ANCRedirectStepDelegate, ANCOpenURLDelegate {
    
    private weak var client: AncileStudyServerClient!
    private var authCompletion: ((Error?) -> ())? = nil

    init(client: AncileStudyServerClient) {
        super.init()
        self.client = client
    }
    
    
    public func redirectViewControllerDidLoad(viewController: ANCRedirectStepViewController) {
        
    }
    
    public func beginRedirect(completion: @escaping ((Error?) -> ())) {
        if let url = self.client.authURL {
            self.authCompletion = completion
            ANCOpenURLManager.safeOpenURL(url: url)
            return
        }
        else {
            self.authCompletion?(nil)
        }
    }
    
    public func handleURL(url: URL) -> Bool {
        
        //check to see if this matches the expected format
        //ancile3ec3082ca348453caa716cc0ec41791e://auth/ancile/callback?code={CODE}
        let pattern = "^\(ANCOpenURLManager.URLScheme)://auth/ancile/callback"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        
        guard let _ = regex.firstMatch(
            in: url.absoluteString,
            options: .init(rawValue: 0),
            range: NSMakeRange(0, url.absoluteString.characters.count)) else {
                return false
        }
        
        if let code = ANCOpenURLManager.getQueryStringParameter(url: url.absoluteString, param: "code") {
            self.client.signIn(code: code) { (signInResponse, error) in
                self.authCompletion?(nil)
            }
            return true
        }
        
        return false
    }

}
