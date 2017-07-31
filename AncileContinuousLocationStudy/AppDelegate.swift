//
//  AppDelegate.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 6/22/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

import UIKit
import OhmageOMHSDK
import ResearchSuiteTaskBuilder
import ResearchSuiteResultsProcessor
import ResearchSuiteAppFramework
import Gloss
import sdlrkx
import CoreLocation
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, UNUserNotificationCenterDelegate  {

    var window: UIWindow?
    var ancileClient: AncileStudyServerClient!
    
    var store: ANCStore!
    var ohmageManager: OhmageOMHManager!
    var taskBuilder: RSTBTaskBuilder!
    var resultsProcessor: RSRPResultsProcessor!
    var activityManager: ANCActivityManager!
    var openURLManager: ANCOpenURLManager!
    var locationManager: CLLocationManager!
    let distance: NSNumber = 150
    let nameHome: String = "home"
    let nameWork: String = "work"
    var locationRegionHome: CLCircularRegion!
    var locationRegionWork: CLCircularRegion!
    
    @available(iOS 10.0, *)
    var center: UNUserNotificationCenter!{
        return UNUserNotificationCenter.current()
    }
    
    func initializeOhmage(credentialsStore: OhmageOMHSDKCredentialStore) -> OhmageOMHManager {
        
        //load OMH client application credentials from OMHClient.plist
        guard let file = Bundle.main.path(forResource: "OMHClient", ofType: "plist") else {
            fatalError("Could not initialze OhmageManager")
        }
        
        
        let omhClientDetails = NSDictionary(contentsOfFile: file)
        
        guard let baseURL = omhClientDetails?["OMHBaseURL"] as? String,
            let clientID = omhClientDetails?["OMHClientID"] as? String,
            let clientSecret = omhClientDetails?["OMHClientSecret"] as? String else {
                fatalError("Could not initialze OhmageManager")
        }
        
        if let ohmageManager = OhmageOMHManager(baseURL: baseURL,
                                                clientID: clientID,
                                                clientSecret: clientSecret,
                                                queueStorageDirectory: "ohmageSDK",
                                                store: credentialsStore) {
            return ohmageManager
        }
        else {
            fatalError("Could not initialze OhmageManager")
        }
        
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        
        self.store.setValueInState(value: true as NSSecureCoding, forKey: "shouldDoDaily")
        NSLog(String(describing: self.store.valueInState(forKey: "shouldDoDaily")))
        let storyboard = UIStoryboard(name: "Splash", bundle: Bundle.main)
        let vc = storyboard.instantiateInitialViewController()
        self.transition(toRootViewController: vc!, animated: true)
    }
    
    
    static var appDelegate: AppDelegate! {
        return UIApplication.shared.delegate! as! AppDelegate
    }
    
    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        debugPrint(url)
        return self.openURLManager.handleURL(url: url)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        self.store = ANCStore()
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.startUpdatingLocation()
        
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            self.locationManager.startMonitoringSignificantLocationChanges()
        }
        

        
        self.ancileClient = AncileStudyServerClient(
            baseURL: "https://ancile.cornelltech.io",
            store: self.store
        )
        
        self.openURLManager = ANCOpenURLManager(openURLDelegates: [
            self.ancileClient.ancileAuthDelegate,
            self.ancileClient.coreAuthDelegate
        ])
        
        self.ohmageManager = self.initializeOhmage(credentialsStore: self.store)
        self.store.setValueInState(value: false as NSSecureCoding, forKey: "shouldDoDaily")

        
        
        
        self.taskBuilder = RSTBTaskBuilder(
            stateHelper: self.store,
            elementGeneratorServices: AppDelegate.elementGeneratorServices,
            stepGeneratorServices: AppDelegate.stepGeneratorServices,
            answerFormatGeneratorServices: AppDelegate.answerFormatGeneratorServices
        )
        
        self.resultsProcessor = RSRPResultsProcessor(
            frontEndTransformers: AppDelegate.resultsTransformers,
            backEnd: ORBEManager(ohmageManager: self.ohmageManager)
        )
        
        self.activityManager = ANCActivityManager(activityFilename: "activities", taskBuilder: self.taskBuilder)
        
        
        
        self.showViewController(animated: false)
        
        if #available(iOS 10.0, *) {
            // self.center = UNUserNotificationCenter.current()
            self.center.delegate = self
            self.center.requestAuthorization(options: [UNAuthorizationOptions.sound ], completionHandler: { (granted, error) in
                if error == nil{
                    // UIApplication.shared.registerForRemoteNotifications()
                }
            })
        } else {
            let settings  = UIUserNotificationSettings(types: [UIUserNotificationType.alert , UIUserNotificationType.badge , UIUserNotificationType.sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            
        }
        
        return true
    }
    
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle code here.
        completionHandler([UNNotificationPresentationOptions.sound , UNNotificationPresentationOptions.alert , UNNotificationPresentationOptions.badge])
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        self.store.setValueInState(value: true as NSSecureCoding, forKey: "shouldDoDaily")
        NSLog(String(describing: self.store.valueInState(forKey: "shouldDoDaily")))
        let storyboard = UIStoryboard(name: "Splash", bundle: Bundle.main)
        let vc = storyboard.instantiateInitialViewController()
        self.transition(toRootViewController: vc!, animated: true)
        
        completionHandler()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
 
    
    
    open func showViewController(animated: Bool) {
        //if not signed in, go to sign in screen
        if !self.ohmageManager.isSignedIn {
            
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let vc = storyboard.instantiateInitialViewController()
            self.transition(toRootViewController: vc!, animated: animated)
            
            
        }
        else {
            
            let storyboard = UIStoryboard(name: "Splash", bundle: Bundle.main)
            let vc = storyboard.instantiateInitialViewController()
            self.transition(toRootViewController: vc!, animated: animated)
            
        }
    }
    
    open func signOut() {
        
        self.ohmageManager.signOut { (error) in
            
            self.store.reset()
            
            DispatchQueue.main.async {
                self.showViewController(animated: true)
            }
            
        }
    }
    
    /**
     Convenience method for transitioning to the given view controller as the main window
     rootViewController.
     */
    open func transition(toRootViewController: UIViewController, animated: Bool, completion: ((Bool) -> Swift.Void)? = nil) {
        guard let window = self.window else { return }
        if (animated) {
            let snapshot:UIView = (self.window?.snapshotView(afterScreenUpdates: true))!
            toRootViewController.view.addSubview(snapshot);
            
            self.window?.rootViewController = toRootViewController;
            
            UIView.animate(withDuration: 0.3, animations: {() in
                snapshot.layer.opacity = 0;
            }, completion: {
                (value: Bool) in
                snapshot.removeFromSuperview()
                completion?(value)
            })
        }
        else {
            window.rootViewController = toRootViewController
            completion?(true)
        }
    }

    
    
    open class var stepGeneratorServices: [RSTBStepGenerator] {
        return [
            RSTBLocationStepGenerator(),
            CTFOhmageLoginStepGenerator(),
            CTFDelayDiscountingStepGenerator(),
            CTFBARTStepGenerator(),
            RSTBInstructionStepGenerator(),
            RSTBTextFieldStepGenerator(),
            RSTBIntegerStepGenerator(),
            RSTBDecimalStepGenerator(),
            RSTBTimePickerStepGenerator(),
            RSTBFormStepGenerator(),
            RSTBDatePickerStepGenerator(),
            RSTBSingleChoiceStepGenerator(),
            RSTBMultipleChoiceStepGenerator(),
            RSTBBooleanStepGenerator(),
            RSTBPasscodeStepGenerator(),
            RSTBScaleStepGenerator(),
            YADLFullStepGenerator(),
            YADLSpotStepGenerator(),
            ANCAncileAuthStepGenerator(),
            ANCCoreAuthStepGenerator()
        ]
    }
    
    open class var answerFormatGeneratorServices:  [RSTBAnswerFormatGenerator] {
        return [
            RSTBLocationStepGenerator(),
            RSTBTextFieldStepGenerator(),
            RSTBIntegerStepGenerator(),
            RSTBDecimalStepGenerator(),
            RSTBTimePickerStepGenerator(),
            RSTBDatePickerStepGenerator(),
            RSTBBooleanStepGenerator(),
            RSTBScaleStepGenerator()
        ]
    }
    
    open class var elementGeneratorServices: [RSTBElementGenerator] {
        return [
            RSTBElementListGenerator(),
            RSTBElementFileGenerator(),
            RSTBElementSelectorGenerator()
        ]
    }
    
    open class var resultsTransformers: [RSRPFrontEndTransformer.Type] {
        return [
            CTFBARTSummaryResultsTransformer.self,
            CTFDelayDiscountingRawResultsTransformer.self,
            YADLSpotRaw.self,
            YADLFullRaw.self,
            ANCWeeklySurveyResult.self
        ]
    }
    
    // Location Manager
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        
        // do nothing: no need to send location always to server
        
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion){
        
        // updates when entered any of the 2 defined regions
        
        let logicalLocation = LogicalLocationSample()
        logicalLocation.locationName = region.identifier
        logicalLocation.action = LogicalLocationSample.Action.enter
        
        logicalLocation.acquisitionSourceCreationDateTime = Date()
        logicalLocation.acquisitionModality = .Sensed
        logicalLocation.acquisitionSourceName = "edu.cornell.tech.foundry.OhmageOMHSDK.Geofence"
        
        self.ohmageManager.addDatapoint(datapoint: logicalLocation, completion: { (error) in
            
            debugPrint(error)
            
        })
        
        NSLog("entered")
        
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region:CLRegion){
        
        // updates when exit any of the 2 defined regions
        
        NSLog("exited region")
        
        let logicalLocation = LogicalLocationSample()
        logicalLocation.locationName = region.identifier
        logicalLocation.action = LogicalLocationSample.Action.exit
        
        logicalLocation.acquisitionSourceCreationDateTime = Date()
        logicalLocation.acquisitionModality = .Sensed
        logicalLocation.acquisitionSourceName = "edu.cornell.tech.foundry.OhmageOMHSDK.Geofence"
        
        self.ohmageManager.addDatapoint(datapoint: logicalLocation, completion: { (error) in
            
            debugPrint(error)
            
        })
    }
    
    // TODO: refactor this code and make it cleaner
    
    func updateMonitoredRegions (regionChanged: String) {
        
        NSLog("start monitoring updated locations")
        
        if(regionChanged == "home"){
            
            // Stop monitoring old region

            let coordinateHomeLatOld = self.store.valueInState(forKey: "saved_region_lat_home") as! CLLocationDegrees
            let coordinateHomeLongOld = self.store.valueInState(forKey: "saved_region_long_home") as! CLLocationDegrees
            let radiusHomeOld = self.store.valueInState(forKey: "saved_region_distance_home") as! Double
            let coordinateHomeOld = CLLocationCoordinate2D(latitude: coordinateHomeLatOld, longitude: coordinateHomeLongOld)
            
            let locationRegionHomeOld = CLCircularRegion(center: coordinateHomeOld, radius: radiusHomeOld, identifier: nameHome as String)
            self.locationManager.stopMonitoring(for: locationRegionHomeOld)

            // Start monitoring new region
            
            let coordinateHomeLat = self.store.valueInState(forKey: "home_coordinate_lat") as! CLLocationDegrees
            let coordinateHomeLong = self.store.valueInState(forKey: "home_coordinate_long") as! CLLocationDegrees
            let coordinateHome = CLLocationCoordinate2D(latitude: coordinateHomeLat, longitude: coordinateHomeLong)
            
            self.locationRegionHome = CLCircularRegion(center: coordinateHome, radius: distance.doubleValue, identifier: nameHome as String)
            self.locationManager.startMonitoring(for:locationRegionHome)
            
            self.store.setValueInState(value: locationRegionHome.center.latitude as NSSecureCoding, forKey: "saved_region_lat_home")
            self.store.setValueInState(value: locationRegionHome.center.longitude as NSSecureCoding, forKey: "saved_region_long_home")
            self.store.setValueInState(value: distance.doubleValue as NSSecureCoding, forKey: "saved_region_distance_home")
            
            self.locationManager.startMonitoringVisits()
            
            
            
        }
        
        if(regionChanged == "work"){
            
            // Stop monitoring old region
            
            let coordinateWorkLatOld = self.store.valueInState(forKey: "saved_region_lat_work") as! CLLocationDegrees
            let coordinateWorkLongOld = self.store.valueInState(forKey: "saved_region_long_work") as! CLLocationDegrees
            let radiusWorkOld = self.store.valueInState(forKey: "saved_region_distance_work") as! Double
            let coordinateWorkOld = CLLocationCoordinate2D(latitude: coordinateWorkLatOld, longitude: coordinateWorkLongOld)
            
            let locationRegionWorkOld = CLCircularRegion(center: coordinateWorkOld, radius: radiusWorkOld, identifier: nameWork as String)
            
            self.locationManager.stopMonitoring(for: locationRegionWorkOld)
            
            
            // Start monitoring new region
            
            let coordinateWorkLat = self.store.valueInState(forKey: "work_coordinate_lat") as! CLLocationDegrees
            let coordinateWorkLong = self.store.valueInState(forKey: "work_coordinate_long") as! CLLocationDegrees
            let coordinateWork = CLLocationCoordinate2D(latitude: coordinateWorkLat, longitude: coordinateWorkLong)
            
            self.locationRegionWork = CLCircularRegion(center: coordinateWork, radius: distance.doubleValue, identifier: nameWork as String)
            self.locationManager.startMonitoring(for:locationRegionWork)
            
            self.store.setValueInState(value: locationRegionWork.center.latitude as NSSecureCoding, forKey: "saved_region_lat_work")
            self.store.setValueInState(value: locationRegionWork.center.longitude as NSSecureCoding, forKey: "saved_region_long_work")
            self.store.setValueInState(value: distance.doubleValue as NSSecureCoding, forKey: "saved_region_distance_work")
            
            self.locationManager.startMonitoringVisits()
            
            
            
        }
        
        if(regionChanged == "onboarding_home"){
            
            let coordinateHomeLat = self.store.valueInState(forKey: "home_coordinate_lat") as! CLLocationDegrees
            let coordinateHomeLong = self.store.valueInState(forKey: "home_coordinate_long") as! CLLocationDegrees
            let coordinateHome = CLLocationCoordinate2D(latitude: coordinateHomeLat, longitude: coordinateHomeLong)
            
            NSLog("saved home coord: ")
            NSLog(String(describing: coordinateHomeLat))
            
            self.locationRegionHome = CLCircularRegion(center: coordinateHome, radius: distance.doubleValue, identifier: nameHome as String)
            self.locationManager.startMonitoring(for:locationRegionHome)
            
            NSLog("location monitored:")
            NSLog(String(describing: locationRegionHome))
            
            self.store.setValueInState(value: locationRegionHome.center.latitude as NSSecureCoding, forKey: "saved_region_lat_home")
            self.store.setValueInState(value: locationRegionHome.center.longitude as NSSecureCoding, forKey: "saved_region_long_home")
            self.store.setValueInState(value: distance.doubleValue as NSSecureCoding, forKey: "saved_region_distance_home")
            
            
        }
        
        if(regionChanged == "onboarding_work"){
            
            
            let coordinateWorkLat = self.store.valueInState(forKey: "work_coordinate_lat") as! CLLocationDegrees
            let coordinateWorkLong = self.store.valueInState(forKey: "work_coordinate_long") as! CLLocationDegrees
            let coordinateWork = CLLocationCoordinate2D(latitude: coordinateWorkLat, longitude: coordinateWorkLong)
            
            self.locationRegionWork = CLCircularRegion(center: coordinateWork, radius: distance.doubleValue, identifier: nameWork as String)
            self.locationManager.startMonitoring(for:locationRegionWork)
            
            self.store.setValueInState(value: locationRegionWork.center.latitude as NSSecureCoding, forKey: "saved_region_lat_work")
            self.store.setValueInState(value: locationRegionWork.center.longitude as NSSecureCoding, forKey: "saved_region_long_work")
            self.store.setValueInState(value: distance.doubleValue as NSSecureCoding, forKey: "saved_region_distance_work")
            
            self.locationManager.startMonitoringVisits()
            
        }
        
        
        
        
    }




}

