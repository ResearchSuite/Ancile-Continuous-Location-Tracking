//
//  ANCAncileAuthDelegate.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 7/17/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

import UIKit
import ResearchSuiteExtensions

//this class handles Ancile Study Server Auth
//In beginRedirect, we save a reference to the closure, then open the url for auth
//in handle url, extract
public class ANCAncileAuthDelegate: NSObject, RSRedirectStepDelegate {
    
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
    
    private weak var client: ANCClient!
    private var urlScheme: String
    private var authCompletion: ((Error?) -> ())? = nil

    init(client: ANCClient, urlScheme: String) {
        self.urlScheme = urlScheme
        super.init()
        self.client = client
    }
    
    public func redirectViewControllerDidLoad(viewController: RSRedirectStepViewController) {
        
    }
    
    public func beginRedirect(completion: @escaping ((Error?) -> ())) {
        if let url = self.client.authURL {
            self.authCompletion = completion
            ANCAncileAuthDelegate.safeOpenURL(url: url)
            return
        }
        else {
            self.authCompletion?(nil)
        }
    }
    
    public func handleURL(app: UIApplication, url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        
        //check to see if this matches the expected format
        //ancile3ec3082ca348453caa716cc0ec41791e://auth/ancile/callback?code={CODE}
        let pattern = "^\(self.urlScheme)://auth/ancile/callback"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        
        guard let _ = regex.firstMatch(
            in: url.absoluteString,
            options: .init(rawValue: 0),
            range: NSMakeRange(0, url.absoluteString.characters.count)) else {
                return false
        }
        
        if let code = ANCAncileAuthDelegate.getQueryStringParameter(url: url.absoluteString, param: "code") {
            self.client.signIn(code: code) { (signInResponse, error) in
                self.authCompletion?(nil)
            }
            return true
        }
        
        return false
    }

}
