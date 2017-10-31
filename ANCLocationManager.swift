//
//  ANCLocationManager.swift
//  AncileContinuousLocationStudy
//
//  Created by James Kizer on 10/22/17.
//  Copyright © 2017 Cornell Tech. All rights reserved.
//

import UIKit
import CoreLocation
import OhmageOMHSDK

class ANCLocationManager: NSObject, CLLocationManagerDelegate {
    
    let locationManager: CLLocationManager
    let ohmageManager: OhmageOMHManager
    
    var initialHome = false
    var initialWork = false
    
    var permissionsCallback: (()->())?
    
    static let radius = 150.0
    
    
    //change this to pure computed property
    var home: CLLocationCoordinate2D? {
        didSet {
            //if new value is nil, stop monitoring
            if let currentHome = home {
                if CLLocationManager.authorizationStatus() == .authorizedAlways {
                    let region = CLCircularRegion(center: currentHome, radius: ANCLocationManager.radius, identifier: "home")
                    self.locationManager.startMonitoring(for: region)
                    self.initialHome = true
                    self.locationManager.requestState(for: region)
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
    
    var work: CLLocationCoordinate2D? {
        didSet {
            //if new value is nil, stop monitoring
            if let currentHome = work {
                if CLLocationManager.authorizationStatus() == .authorizedAlways {
                    let region = CLCircularRegion(center: currentHome, radius: ANCLocationManager.radius, identifier: "work")
                    self.locationManager.startMonitoring(for: region)
                    self.initialWork = true
                    self.locationManager.requestState(for: region)
                }
            }
            else {
                
                //clear in store
                if let previousHome = oldValue {
                    let region = CLCircularRegion(center: previousHome, radius: ANCLocationManager.radius, identifier: "work")
                    self.locationManager.stopMonitoring(for: region)
                }
            }
        }
    }

    public init(ohmageManager: OhmageOMHManager) {
        
        self.ohmageManager = ohmageManager
        self.locationManager = CLLocationManager()
        
        super.init()
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        debugPrint(authorizationStatus)
        
        // Set the delegate
        self.locationManager.delegate = self
        
    }
    
    func recordEvent(regionIdentifier: String, action: LogicalLocationResult.Action) {
        let logicalLocationResult = LogicalLocationResult(
            uuid: UUID(),
            taskIdentifier: "ANCLocationManager",
            taskRunUUID: UUID(),
            locationName: regionIdentifier,
            action: action,
            eventTimestamp: Date()
        )
        
        self.ohmageManager.addDatapoint(datapoint: logicalLocationResult, completion: { (error) in
            
            debugPrint(error)
            
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion){
        self.recordEvent(regionIdentifier: region.identifier, action: .enter)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region:CLRegion){
        self.recordEvent(regionIdentifier: region.identifier, action: .exit)
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        
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
