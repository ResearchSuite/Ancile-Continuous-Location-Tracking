//
//  ANCCoreAuthDelegate.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 7/17/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

import UIKit
import ResearchSuiteExtensions

public class ANCCoreAuthDelegate: NSObject, RSRedirectStepDelegate {

    public static func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
    
    public static func safeOpenURL(url: URL) {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            // Fallback on earlier versions
            UIApplication.shared.openURL(url)
        }
    }
    
    private var urlScheme: String
    private weak var client: ANCClient!
    private var authCompletion: ((Error?) -> ())? = nil
    
    init(client: ANCClient, urlScheme: String) {
        self.urlScheme = urlScheme
        super.init()
        self.client = client
    }
    
    
    public func redirectViewControllerDidLoad(viewController: RSRedirectStepViewController) {
        
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
                ANCCoreAuthDelegate.safeOpenURL(url: url)
                return
            }
            else {
                self.authCompletion?(nil)
            }
            
        }
    }
    
    public func handleURL(app: UIApplication, url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        
        //check to see if this matches the expected format
        //ancile3ec3082ca348453caa716cc0ec41791e://auth/ancile/callback?code={CODE}
        let pattern = "^\(self.urlScheme)://auth/ancile/confirm_core_auth"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        
        guard let _ = regex.firstMatch(
            in: url.absoluteString,
            options: .init(rawValue: 0),
            range: NSMakeRange(0, url.absoluteString.characters.count)) else {
                return false
        }
        
        if let successString = ANCCoreAuthDelegate.getQueryStringParameter(url: url.absoluteString, param: "success") {
            
            self.authCompletion?(nil)
            return true
            
        }
        
        return false
    }
    
}
