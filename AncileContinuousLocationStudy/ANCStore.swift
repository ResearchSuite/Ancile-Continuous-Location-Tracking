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
import CoreLocation

open class ANCStore: NSObject, OhmageOMHSDKCredentialStore, RSTBStateHelper, OhmageManagerProvider, ANCClientProvider, ANCClientCredentialStore {
    
    
    static public let kConsentDocURL = "ancile_study_consent_doc_URL"
    static public let kLastSurveyCompletionTime = "ancile_study_last_survey_completion_time"
    static public let kLastSurveyLaunchTime = "ancile_study_last_survey_launch_time"
    static public let kEligible = "ancile_study_eligible"
    static public let kPartcipantSince = "ancile_participant_since"
    static public let kNotificationTime = "ancile_notification_time"

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
    
    open var homeLocation: CLLocationCoordinate2D? {
        get {
            if let lat = self.get(key: "home_coordinate_lat") as? CLLocationDegrees,
                let lng = self.get(key: "home_coordinate_lng") as? CLLocationDegrees {
                return CLLocationCoordinate2D(latitude: lat, longitude: lng)
            }
            else {
                return nil
            }
        }
        set {
            if let location = homeLocation {
                self.set(value: NSNumber(value: location.latitude), key: "home_coordinate_lat")
                self.set(value: NSNumber(value: location.longitude), key: "home_coordinate_lng")
            }
            else {
                self.set(value: nil, key: "home_coordinate_lat")
                self.set(value: nil, key: "home_coordinate_lng")
            }
            
        }
    }
    
    open var participantSince: Date? {
        get {
            return self.get(key: ANCStore.kPartcipantSince) as? Date
        }
        set {
            if let date = newValue {
                self.set(value: date as NSDate, key: ANCStore.kPartcipantSince)
            }
            else {
                self.set(value: nil, key: ANCStore.kPartcipantSince)
            }
        }
    }
    
    open var notificationTime: DateComponents? {
        get {
            return self.get(key: ANCStore.kNotificationTime) as? DateComponents
        }
        set {
            if let dateComponents = newValue {
                self.set(value: dateComponents as NSDateComponents, key: ANCStore.kNotificationTime)
            }
            else {
                self.set(value: nil, key: ANCStore.kNotificationTime)
            }
        }
    }
    
 
}
