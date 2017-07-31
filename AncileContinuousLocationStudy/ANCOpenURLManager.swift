//
//  ANCOpenURLManager.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 7/17/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

import UIKit

open class ANCOpenURLManager: NSObject {
    
    static public let URLScheme: String = "ancile3ec3082ca348453caa716cc0ec41791e"
    
    var openURLDelegates: [ANCOpenURLDelegate]
    
    public init(
        openURLDelegates: [ANCOpenURLDelegate]?
        ) {
        self.openURLDelegates = openURLDelegates ?? []
        super.init()
    }
    
    open func handleURL(url: URL) -> Bool {
        let delegates = self.openURLDelegates
        for delegate in delegates {
            let handled = delegate.handleURL(url: url)
            if handled { return true }
        }
        return false
    }
    
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

}
