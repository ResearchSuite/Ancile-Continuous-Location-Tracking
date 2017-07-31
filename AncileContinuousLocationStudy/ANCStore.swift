//
//  ANCStore.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 7/10/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

import UIKit
import OhmageOMHSDK
import ResearchSuiteTaskBuilder
import ResearchSuiteAppFramework

open class ANCStore: NSObject, OhmageOMHSDKCredentialStore, RSTBStateHelper, OhmageManagerProvider, AncileClientProvider {
    
    static public let kAncileAuthToken = "ancile_study_server_auth_token"

    public func valueInState(forKey: String) -> NSSecureCoding? {
        return self.get(key: forKey)
    }
    
    public func setValueInState(value: NSSecureCoding?, forKey: String) {
        self.set(value: value, key: forKey)
    }
    
    public func set(value: NSSecureCoding?, key: String) {
        RSAFKeychainStateManager.setValueInState(value: value, forKey: key)
    }
    public func get(key: String) -> NSSecureCoding? {
        return RSAFKeychainStateManager.valueInState(forKey: key)
    }
    
    public func getOhmageManager() -> OhmageOMHManager? {
        return (UIApplication.shared.delegate as? AppDelegate)?.ohmageManager
    }
    
    public func getAncileClient() -> AncileStudyServerClient? {
        return (UIApplication.shared.delegate as? AppDelegate)?.ancileClient
    }
    
    public func reset() {
        RSAFKeychainStateManager.clearKeychain()
    }
    
}
