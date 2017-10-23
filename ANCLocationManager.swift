//
//  ANCLocationManager.swift
//  AncileContinuousLocationStudy
//
//  Created by James Kizer on 10/22/17.
//  Copyright © 2017 Christina Tsangouri. All rights reserved.
//

import UIKit
import CoreLocation
import OhmageOMHSDK

class ANCLocationManager: NSObject, CLLocationManagerDelegate {
    
    let locationManager: CLLocationManager
    let ohmageManager: OhmageOMHManager
    
    static let radius = 150.0
    
    var home: CLLocationCoordinate2D? {
        didSet {
            //if new value is nil, stop monitoring
            if let currentHome = home {
                self.locationManager.requestAlwaysAuthorization()
                let region = CLCircularRegion(center: currentHome, radius: ANCLocationManager.radius, identifier: "home")
                self.locationManager.startMonitoring(for: region)
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
            if let currentHome = home {
                self.locationManager.requestAlwaysAuthorization()
                let region = CLCircularRegion(center: currentHome, radius: ANCLocationManager.radius, identifier: "work")
                self.locationManager.startMonitoring(for: region)
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
        
//        guard authorizationStatus != .restricted && authorizationStatus != .denied else {
//            return
//        }
        
        // Create a location manager object
        
        
        // Set the delegate
        self.locationManager.delegate = self
        
        // Request location authorization
        self.locationManager.requestAlwaysAuthorization()
//        
//        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
//            guard let locations = NSArray(contentsOfFile: Bundle.main.path(forResource: "Locations", ofType: "plist")!) as? [NSDictionary] else {
//                return
//            }
//            
//            locations.forEach { (locationDict) in
//                debugPrint(locationDict)
//                
//                guard let name = locationDict["name"] as? NSString,
//                    let lat = locationDict["latitude"]  as? NSNumber,
//                    let long = locationDict["longitude"]  as? NSNumber,
//                    let radius = locationDict["radius"]  as? NSNumber else {
//                        return
//                }
//                
//                let center = CLLocationCoordinate2D(latitude: lat.doubleValue, longitude: long.doubleValue)
//                let locationRegion = CLCircularRegion(center: center, radius: radius.doubleValue, identifier: name as String)
//                
//                let log = "Starting to monitor location: \(locationRegion.debugDescription)"
//                LogManager.sharedInstance.log(log)
//                
//                self.locationManager.startMonitoring(for: locationRegion)
//            }
//        }
//        
//        self.locationManager.startMonitoringVisits()
        
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion){
        
        // updates when entered any of the 2 defined regions
        
//        let logicalLocation = LogicalLocationSample()
//        logicalLocation.locationName = region.identifier
//        logicalLocation.action = LogicalLocationSample.Action.enter
//
//        logicalLocation.acquisitionSourceCreationDateTime = Date()
//        logicalLocation.acquisitionModality = .Sensed
//        logicalLocation.acquisitionSourceName = "edu.cornell.tech.foundry.OhmageOMHSDK.Geofence"
        
        let logicalLocationResult = LogicalLocationResult(
            uuid: UUID(),
            taskIdentifier: "ANCLocationManager",
            taskRunUUID: UUID(),
            locationName: region.identifier,
            action: .enter,
            eventTimestamp: Date()
        )
        
        self.ohmageManager.addDatapoint(datapoint: logicalLocationResult, completion: { (error) in
            
            debugPrint(error)
            
        })
        
        NSLog("entered")
        
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region:CLRegion){
        
        // updates when exit any of the 2 defined regions
        
        NSLog("exited region")
        
//        let logicalLocation = LogicalLocationSample()
//        logicalLocation.locationName = region.identifier
//        logicalLocation.action = LogicalLocationSample.Action.exit
//
//        logicalLocation.acquisitionSourceCreationDateTime = Date()
//        logicalLocation.acquisitionModality = .Sensed
//        logicalLocation.acquisitionSourceName = "edu.cornell.tech.foundry.OhmageOMHSDK.Geofence"

        let logicalLocationResult = LogicalLocationResult(
            uuid: UUID(),
            taskIdentifier: "ANCLocationManager",
            taskRunUUID: UUID(),
            locationName: region.identifier,
            action: .exit,
            eventTimestamp: Date()
        )
        
        self.ohmageManager.addDatapoint(datapoint: logicalLocationResult, completion: { (error) in
            
            debugPrint(error)
            
        })
    }
    

}
