//
//  ANCLocationManager.swift
//  AncileContinuousLocationStudy
//
//  Created by James Kizer on 10/22/17.
//  Copyright © 2017 Cornell Tech. All rights reserved.
//

import UIKit
import CoreLocation
//import OhmageOMHSDK
import MobileCacheSDK

class ANCLocationManager: NSObject, CLLocationManagerDelegate {
    
    let locationManager: CLLocationManager
//    let ohmageManager: OhmageOMHManager
    let mcManager: MCManager
    let store: ANCStore
    
    var initialHome = false
    var initialWork = false
    
    var permissionsCallback: (()->())?
    
    static let radius = 150.0
    
    
    
    func delay(_ delay:TimeInterval, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
    
    //change this to pure computed property
    var _home: CLLocationCoordinate2D? = nil
    var home: CLLocationCoordinate2D? {
        get {
            if self._home == nil {
                self._home = self.store.homeLocation
            }
            return self._home
        }
        set(newValue) {
            let oldValue = self._home
            self._home = newValue
            self.store.homeLocation = newValue
            
            debugPrint("Setting Home")
            
            if let currentHome = newValue {
                if CLLocationManager.authorizationStatus() == .authorizedAlways {
                    let region = CLCircularRegion(center: currentHome, radius: ANCLocationManager.radius, identifier: "home")
                    self.locationManager.startMonitoring(for: region)
                    self.initialHome = true
                    debugPrint("Requesting State For Home")
                    
                    //These requests don't seem to always be working
                    //Add a delay
                    let locationManager = self.locationManager
                    delay(5.0) {
                        locationManager.requestState(for: region)
                    }
                    
                }
            }
            else {
                
                //clear in store
                if let previousHome = oldValue {
                    let region = CLCircularRegion(center: previousHome, radius: ANCLocationManager.radius, identifier: "home")
                    self.locationManager.stopMonitoring(for: region)
                }
            }
        }
    }
    
    var _work: CLLocationCoordinate2D? = nil
    var work: CLLocationCoordinate2D? {
        get {
            if self._work == nil {
                self._work = self.store.workLocation
            }
            return self._work
        }
        set(newValue) {
            let oldValue = self._work
            self._work = newValue
            self.store.workLocation = newValue
            debugPrint("Setting Work")
            
            if let currentWork = newValue {
                if CLLocationManager.authorizationStatus() == .authorizedAlways {
                    let region = CLCircularRegion(center: currentWork, radius: ANCLocationManager.radius, identifier: "work")
                    self.locationManager.startMonitoring(for: region)
                    self.initialWork = true
                    debugPrint("Requesting State For Work")
                    //These requests don't seem to always be working
                    //Add a delay
                    let locationManager = self.locationManager
                    delay(10.0) {
                        locationManager.requestState(for: region)
                    }
                }
            }
            else {
                
                //clear in store
                if let previousWork = oldValue {
                    let region = CLCircularRegion(center: previousWork, radius: ANCLocationManager.radius, identifier: "work")
                    self.locationManager.stopMonitoring(for: region)
                }
            }
        }
    }

    public init(mcManager: MCManager, store: ANCStore) {
        
        self.mcManager = mcManager
        self.store = store
        self.locationManager = CLLocationManager()
        
        super.init()
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        debugPrint(authorizationStatus)
        
        // Set the delegate
        self.locationManager.delegate = self
        
    }
    
    public func clearRegions() {
        if self.home != nil {
            self.home = nil
        }
        
        if self.work != nil {
            self.work = nil
        }
    }
    
    func recordEvent(regionIdentifier: String, action: LogicalLocationResult.Action) {
//        let logicalLocationResult = LogicalLocationResult(
//            uuid: UUID(),
//            taskIdentifier: "ANCLocationManager",
//            taskRunUUID: UUID(),
//            locationName: regionIdentifier,
//            action: regionIdentifier,
//            eventTimestamp: Date()
//        )
//
//        debugPrint(logicalLocationResult)
//        debugPrint("Recording event for \(regionIdentifier): \(action.rawValue)")
        
        let logicalLocationSample = MCLogicalLocationSample(date: Date(), location: regionIdentifier, action: action.rawValue)
        self.mcManager.addSample(sample: logicalLocationSample) { (error) in
            debugPrint(error)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion){
        self.recordEvent(regionIdentifier: region.identifier, action: .enter)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region:CLRegion){
        self.recordEvent(regionIdentifier: region.identifier, action: .exit)
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        
        debugPrint("Determined state for \(region.identifier): \(state.rawValue)")
        
        if region.identifier == "home" &&
            self.initialHome {
            self.initialHome = false
        }
        else if region.identifier == "work" &&
            self.initialWork {
            self.initialWork = false
        }
        else {
            return
        }
        
        let action: LogicalLocationResult.Action = {
            if state == .inside {
                return .startedInside
            }
            else if state == .outside {
                return .startedOutside
            }
            else {
                return .startedUnknown
            }
        }()
        
        self.recordEvent(regionIdentifier: region.identifier, action: action)
    }
    
    func requestPermissions(completion: @escaping ()->()) {
        
        self.permissionsCallback = completion
        self.locationManager.requestAlwaysAuthorization()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        self.permissionsCallback?()
        self.permissionsCallback = nil
        
    }
    

}
