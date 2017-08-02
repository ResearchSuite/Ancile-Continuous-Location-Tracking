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
import AncileStudyServerClient
import ResearchKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, ORKPasscodeDelegate, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    
    static public let URLScheme: String = "ancile3ec3082ca348453caa716cc0ec41791e"
    
    var window: UIWindow?
    var ancileClient: ANCClient!
    
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
    
    func signOut() {
        
        ANCNotificationManager.cancelNotifications()
        
        self.ohmageManager.signOut { (error) in
            self.ancileClient.signOut()
            
            if let consentDocURL = self.store.consentDocURL {
                do {
                    try FileManager.default.removeItem(at: consentDocURL)
                }
                catch let error as NSError {
                    print(error.localizedDescription)
                }
                
            }
            
            self.store.reset()
            
            
            
            self.showViewController(animated: true)
        }
    }
    
    var isSignedIn: Bool {
        return self.ancileClient.isSignedIn //&& //self.ohmageManager.isSignedIn
    }
    
    var isPasscodeSet: Bool {
        return ORKPasscodeViewController.isPasscodeStoredInKeychain()
    }
    
    var isConsented: Bool {
        return self.store.isConsented
    }
    
    var isEligible: Bool {
        return self.store.isEligible
    }
  
    
    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
    
    /**
     Convenience method for presenting a modal view controller.
     */
    open func presentViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        guard let rootVC = self.window?.rootViewController else { return }
        var topViewController: UIViewController = rootVC
        while (topViewController.presentedViewController != nil) {
            topViewController = topViewController.presentedViewController!
        }
        topViewController.present(viewController, animated: animated, completion: completion)
    }
    
    /**
     Convenience method for transitioning to the given view controller as the main window
     rootViewController.
     */
    open func transition(toRootViewController: UIViewController, animated: Bool) {
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
            })
        }
        else {
            window.rootViewController = toRootViewController
        }
    }
    
    open func storyboardIDForCurrentState() -> String {
        if self.isEligible &&
            self.isConsented &&
            //self.isSignedIn &&
            self.isPasscodeSet {
            return "Splash"
        }
        else {
            return "Main"
        }
    }
    
    open func showViewController(animated: Bool) {
        
        guard let _ = self.window else {
            return
        }
        
        let storyboard = UIStoryboard(name: self.storyboardIDForCurrentState(), bundle: nil)
        let vc = storyboard.instantiateInitialViewController()
        self.transition(toRootViewController: vc!, animated: animated)
        
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        if UserDefaults.standard.object(forKey: "FirstRun") == nil {
            UserDefaults.standard.set("1stRun", forKey: "FirstRun")
            UserDefaults.standard.synchronize()
            do {
                try ORKKeychainWrapper.resetKeychain()
            } catch let error {
                print("Got error \(error) when resetting keychain")
            }
            ANCNotificationManager.cancelNotifications()
        }
        
        self.store = ANCStore()
        
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.startUpdatingLocation()
        
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            self.locationManager.startMonitoringSignificantLocationChanges()
        }
        
        self.ancileClient = ANCClient(
            baseURL: "https://ancile.cornelltech.io",
            mobileURLScheme: AppDelegate.URLScheme,
            store: self.store
        )
        
        self.ohmageManager = self.initializeOhmage(credentialsStore: self.store)
        
        self.store.setValueInState(value: false as NSSecureCoding, forKey: "shouldDoDaily")

        
        self.openURLManager = ANCOpenURLManager(openURLDelegates: [
            self.ancileClient.ancileAuthDelegate,
            self.ancileClient.coreAuthDelegate,
            self.ohmageManager
            ])
        
        self.taskBuilder = RSTBTaskBuilder(
            stateHelper: self.store,
            elementGeneratorServices: AppDelegate.elementGeneratorServices,
            stepGeneratorServices: AppDelegate.stepGeneratorServices,
            answerFormatGeneratorServices: AppDelegate.answerFormatGeneratorServices,
            consentDocumentGeneratorServices: AppDelegate.consentDocumentGeneratorServices,
            consentSectionGeneratorServices: AppDelegate.consentSectionGeneratorServices,
            consentSignatureGeneratorServices: AppDelegate.consentSignatureGeneratorServices
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
        
        //ANCNotificationManager.printPendingNotifications()
        
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

    
    open func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        lockScreen()
        return true
    }
    
    // ------------------------------------------------
    // MARK: Passcode Display Handling
    // ------------------------------------------------
    
    private weak var passcodeViewController: UIViewController?
    
    /**
     Should the passcode be displayed. By default, if there isn't a catasrophic error,
     the user is registered and there is a passcode in the keychain, then show it.
     */
    open func shouldShowPasscode() -> Bool {
        return (self.passcodeViewController == nil) &&
            ORKPasscodeViewController.isPasscodeStoredInKeychain()
    }
    
    private func instantiateViewControllerForPasscode() -> UIViewController? {
        return ORKPasscodeViewController.passcodeAuthenticationViewController(withText: nil, delegate: self)
    }
    
    public func lockScreen() {
        
        guard self.shouldShowPasscode(), let vc = instantiateViewControllerForPasscode() else {
            return
        }
        
        window?.makeKeyAndVisible()
        
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .coverVertical
        
        passcodeViewController = vc
        presentViewController(vc, animated: false, completion: nil)
    }
    
    private func dismissPasscodeViewController(_ animated: Bool) {
        self.passcodeViewController?.presentingViewController?.dismiss(animated: animated, completion: nil)
    }
    
    private func resetPasscode() {
        
        // Dismiss the view controller unanimated
        dismissPasscodeViewController(false)
        
        self.signOut()
    }
    
    // MARK: ORKPasscodeDelegate
    
    open func passcodeViewControllerDidFinish(withSuccess viewController: UIViewController) {
        dismissPasscodeViewController(true)
    }
    
    open func passcodeViewControllerDidFailAuthentication(_ viewController: UIViewController) {
        // Do nothing in default implementation
    }
    
    open func passcodeViewControllerForgotPasscodeTapped(_ viewController: UIViewController) {
        
        let title = "Reset Passcode"
        let message = "In order to reset your passcode, you'll need to log out of the app completely and log back in using your email and password."
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        let logoutAction = UIAlertAction(title: "Log Out", style: .destructive, handler: { _ in
            self.resetPasscode()
        })
        alert.addAction(logoutAction)
        
        viewController.present(alert, animated: true, completion: nil)
    }
    
    func setContentHidden(vc: UIViewController, contentHidden: Bool) {
        if let vc = vc.presentedViewController {
            vc.view.isHidden = contentHidden
        }
        
        vc.view.isHidden = contentHidden
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        if shouldShowPasscode() {
            // Hide content so it doesn't appear in the app switcher.
            if let vc = self.window?.rootViewController {
                self.setContentHidden(vc: vc, contentHidden: true)
            }
            
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        lockScreen()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        // Make sure that the content view controller is not hiding content
        if let vc = self.window?.rootViewController {
            self.setContentHidden(vc: vc, contentHidden: false)
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        debugPrint(url)
        return self.openURLManager.handleURL(app: app, url: url, options: options)
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
            ANCCoreAuthStepGenerator(),
            CTFOhmageRedirectLoginStepGenerator(),
            RSTBVisualConsentStepGenerator(),
            RSTBConsentReviewStepGenerator()
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
    
    open class var consentDocumentGeneratorServices: [RSTBConsentDocumentGenerator.Type] {
        return [
            RSTBStandardConsentDocument.self
        ]
    }
    
    open class var consentSectionGeneratorServices: [RSTBConsentSectionGenerator.Type] {
        return [
            RSTBStandardConsentSectionGenerator.self
        ]
    }
    
    open class var consentSignatureGeneratorServices: [RSTBConsentSignatureGenerator.Type] {
        return [
            RSTBParticipantConsentSignatureGenerator.self,
            RSTBInvestigatorConsentSignatureGenerator.self
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
    
    // LOCATION MANAGER
    
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
