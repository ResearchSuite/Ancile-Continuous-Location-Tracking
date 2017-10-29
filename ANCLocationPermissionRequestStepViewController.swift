//
//  ANCLocationPermissionRequestStepViewController.swift
//  AncileContinuousLocationStudy
//
//  Created by James Kizer on 10/27/17.
//

import UIKit
import ResearchSuiteExtensions
import CoreLocation

class ANCLocationPermissionRequestStepViewController: RSQuestionViewController {

    override open func viewDidLoad() {
        super.viewDidLoad()
        
        if let step = self.step as? ANCLocationPermissionRequestStep {
            self.setContinueButtonTitle(title: step.buttonText)
        }
        
    }
    
    override open func continueTapped(_ sender: Any) {
        
        if !CLLocationManager.locationServicesEnabled() {
            let alertController = UIAlertController(title: "Location Services Disabled", message: "Please turn on location services to continue.", preferredStyle: UIAlertControllerStyle.alert)
            
            // Replace UIAlertActionStyle.Default by UIAlertActionStyle.default
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                (result : UIAlertAction) -> Void in
                print("OK")
            }
            
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
        
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            let alertController = UIAlertController(title: "Geofence Monitoring Not Supported", message: "Your phone does not support geofencing.", preferredStyle: UIAlertControllerStyle.alert)
            
            // Replace UIAlertActionStyle.Default by UIAlertActionStyle.default
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                (result : UIAlertAction) -> Void in
                print("OK")
            }
            
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
        
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            //continue
            self.notifyDelegateAndMoveForward()
        }
        else if CLLocationManager.authorizationStatus() == .notDetermined {
            AppDelegate.appDelegate.locationManager.requestPermissions {
                if CLLocationManager.authorizationStatus() == .authorizedAlways {
                    //continue
                    self.notifyDelegateAndMoveForward()
                }
                else {
                    let alertController = UIAlertController(title: "Geofence Monitoring Not Permitted", message: "The application may not function properly", preferredStyle: UIAlertControllerStyle.alert)
                    
                    // Replace UIAlertActionStyle.Default by UIAlertActionStyle.default
                    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                        (result : UIAlertAction) -> Void in
                        print("OK")
                    }
                    
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
        
    }

}
