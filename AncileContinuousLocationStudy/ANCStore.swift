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
import AncileStudyServerClient

open class ANCStore: NSObject, OhmageOMHSDKCredentialStore, RSTBStateHelper, OhmageManagerProvider, ANCClientProvider, ANCClientCredentialStore {
    
    
    static public let kConsentDocURL = "ancile_study_consent_doc_URL"
    static public let kLastSurveyCompletionTime = "ancile_study_last_survey_completion_time"
    static public let kLastSurveyLaunchTime = "ancile_study_last_survey_launch_time"
    static public let kEligible = "ancile_study_eligible"

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
    
    public func getAncileClient() -> ANCClient? {
        return (UIApplication.shared.delegate as? AppDelegate)?.ancileClient
    }
    
    public func reset() {
        RSAFKeychainStateManager.clearKeychain()
    }
    
    //app specific state
    open var consentDocURL: URL? {
        get {
            return self.get(key: ANCStore.kConsentDocURL) as? URL
        }
        set {
            if let url = newValue {
                self.set(value: url as NSURL, key: ANCStore.kConsentDocURL)
            }
            else {
                self.set(value: nil, key: ANCStore.kConsentDocURL)
            }
        }
    }
    
    open var isConsented: Bool {
        return self.consentDocURL != nil
    }
    
    open var lastSurveyCompletionTime: Date? {
        get {
            return self.get(key: ANCStore.kLastSurveyCompletionTime) as? Date
        }
        set {
            if let date = newValue {
                self.set(value: date as NSDate, key: ANCStore.kLastSurveyCompletionTime)
            }
            else {
                self.set(value: nil, key: ANCStore.kLastSurveyCompletionTime)
            }
        }
    }
    
    open var lastSurveyLaunchTime: Date? {
        get {
            return self.get(key: ANCStore.kLastSurveyLaunchTime) as? Date
        }
        set {
            if let date = newValue {
                self.set(value: date as NSDate, key: ANCStore.kLastSurveyLaunchTime)
            }
            else {
                self.set(value: nil, key: ANCStore.kLastSurveyLaunchTime)
            }
        }
    }
    
    open var isEligible: Bool {
        get {
            if let number = self.get(key: ANCStore.kEligible) as? NSNumber {
                return number.boolValue
            }
            else {
                return false
            }
        }
        set {
            let number = NSNumber(booleanLiteral: newValue)
            self.set(value: number, key: ANCStore.kEligible)
        }
    }
    
 
}
