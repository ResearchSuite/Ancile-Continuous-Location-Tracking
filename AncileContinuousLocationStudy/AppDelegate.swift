//
//  AppDelegate.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 6/22/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

import UIKit
import ResearchSuiteTaskBuilder
import ResearchSuiteResultsProcessor
import ResearchSuiteAppFramework
import Gloss
import sdlrkx
import CoreLocation
import AncileStudyServerClient
import ResearchKit
import UserNotifications
import MobileCacheSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, ORKPasscodeDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    var ancileClient: ANCClient!
    
    var store: ANCStore!
//    var ohmageManager: OhmageOMHManager!
    var mcManager: MCManager!
    var taskBuilder: RSTBTaskBuilder!
    var resultsProcessor: RSRPResultsProcessor!
    var activityManager: ANCActivityManager!
    var openURLManager: ANCOpenURLManager!
    var locationManager: ANCLocationManager!
//    let distance: NSNumber = 150
//    let nameHome: String = "home"
//    let nameWork: String = "work"
//    var locationRegionHome: CLCircularRegion!
//    var locationRegionWork: CLCircularRegion!
    
    func initializeMobileCache(credentialsStore: MCCredentialStore) -> MCManager {
        
        //load OMH client application credentials from OMHClient.plist
        guard let file = Bundle.main.path(forResource: "MobileCacheClient", ofType: "plist") else {
            fatalError("Could not initialze OhmageManager")
        }
        
        
        let omhClientDetails = NSDictionary(contentsOfFile: file)
        
        guard let baseURL = omhClientDetails?["baseURL"] as? String,
            let clientID = omhClientDetails?["clientID"] as? String,
            let clientSecret = omhClientDetails?["clientSecret"] as? String,
            let mobileURLScheme = omhClientDetails?["mobileURLScheme"] as? String else {
                fatalError("Could not initialze OhmageManager")
        }
        
        let redirectURL = "\(mobileURLScheme)://exchange"
        
        if let mcManager = MCManager(
            baseURL: baseURL,
            redirectURL: redirectURL,
            clientID: clientID,
            clientSecret: clientSecret,
            queueStorageDirectory: "mobileCache",
            sampleClasses: [MCDefaultSample.self, MCLogicalLocationSample.self, MCDistanceSample.self],
            store: credentialsStore
            ) {
            return mcManager
        }
        else {
            fatalError("Could not initialze Mobile Cache Manager")
        }

    }
    
//    func initializeOhmage(credentialsStore: OhmageOMHSDKCredentialStore) -> OhmageOMHManager {
//
//        //load OMH client application credentials from OMHClient.plist
//        guard let file = Bundle.main.path(forResource: "OMHClient", ofType: "plist") else {
//            fatalError("Could not initialze OhmageManager")
//        }
//
//
//        let omhClientDetails = NSDictionary(contentsOfFile: file)
//
//        guard let baseURL = omhClientDetails?["OMHBaseURL"] as? String,
//            let clientID = omhClientDetails?["OMHClientID"] as? String,
//            let clientSecret = omhClientDetails?["OMHClientSecret"] as? String else {
//                fatalError("Could not initialze OhmageManager")
//        }
//
//        if let ohmageManager = OhmageOMHManager(baseURL: baseURL,
//                                                clientID: clientID,
//                                                clientSecret: clientSecret,
//                                                queueStorageDirectory: "ohmageSDK",
//                                                store: credentialsStore) {
//            return ohmageManager
//        }
//        else {
//            fatalError("Could not initialze OhmageManager")
//        }
//
//    }
    
    func initializeAncile(credentialsStore: ANCClientCredentialStore) -> ANCClient {
        
        //load Ancile client application credentials from AncileClient.plist
        guard let file = Bundle.main.path(forResource: "AncileClient", ofType: "plist") else {
            fatalError("Could not initialze AncileClient")
        }
        
        
        let omhClientDetails = NSDictionary(contentsOfFile: file)
        
        guard let baseURL = omhClientDetails?["AncileBaseURL"] as? String,
            let clientID = omhClientDetails?["AncileStudyID"] as? String,
            let urlScheme = omhClientDetails?["AncileMobileURLScheme"] as? String else {
                fatalError("Could not initialze AncileClient")
        }
        
        return ANCClient(
            baseURL: baseURL,
            ancileClientID: clientID,
            mobileURLScheme: urlScheme,
            store: credentialsStore
        )
        
    }
    
//    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
//
//        self.store.setValueInState(value: true as NSSecureCoding, forKey: "shouldDoDaily")
//        NSLog(String(describing: self.store.valueInState(forKey: "shouldDoDaily")))
//        let storyboard = UIStoryboard(name: "Splash", bundle: Bundle.main)
//        let vc = storyboard.instantiateInitialViewController()
//        self.transition(toRootViewController: vc!, animated: true)
//    }
    
    static var appDelegate: AppDelegate! {
        return UIApplication.shared.delegate! as! AppDelegate
    }
    
    func signOut() {
        
        ANCNotificationManager.cancelNotifications()
        self.locationManager.clearRegions()
        
        self.mcManager.signOut { (error) in
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
        return self.ancileClient.isSignedIn && self.mcManager.isSignedIn
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
    
    var notificationTimeSet: Bool {
        return self.store.notificationTime != nil
    }
    
    var locationsSet: Bool {
        return self.store.locationsSet
    }
    
    func requestLocationPermissions() {
        self.locationManager.locationManager.requestAlwaysAuthorization()
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
            self.isSignedIn &&
            self.isPasscodeSet &&
            self.notificationTimeSet &&
            self.locationsSet {
            return "home"
        }
        else {
            return "onboarding"
        }
    }
    
    open func showViewController(animated: Bool) {
        
        if self.isSignedIn && !self.isPasscodeSet {
            self.signOut()
            return
        }
        
        if !self.isSignedIn && self.isPasscodeSet {
            self.signOut()
            return
        }
        
        guard let _ = self.window else {
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: self.storyboardIDForCurrentState())
        self.transition(toRootViewController: vc, animated: animated)
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
       
        self.window?.tintColor = UIColor(red: 1, green: 0.6784, blue: 0, alpha: 1.0)//UIColor(red:1.00, green:0.80, blue:0.00, alpha:1.0)
     //   [self.window setTintColor:[UIColor greenColor]];
        
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
        
        self.ancileClient = self.initializeAncile(credentialsStore: self.store)

//        self.ohmageManager = self.initializeOhmage(credentialsStore: self.store)
        self.mcManager = self.initializeMobileCache(credentialsStore: self.store)
        
        self.locationManager = ANCLocationManager(mcManager: self.mcManager, store: self.store)
        
        self.store.setValueInState(value: false as NSSecureCoding, forKey: "shouldDoDaily")
        
        self.openURLManager = ANCOpenURLManager(openURLDelegates: [
            self.ancileClient.ancileAuthDelegate,
            self.ancileClient.coreAuthDelegate,
            self.mcManager
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
            backEnd: MCBackEnd(manager: self.mcManager, transformers: [MCDefaultTransformer.self])
        )
        
        self.activityManager = ANCActivityManager(activityFilename: "activities", taskBuilder: self.taskBuilder)
        
        self.showViewController(animated: false)
        
        return true
    }
    
//    @available(iOS 10.0, *)
//    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        // Handle code here.
//        completionHandler([UNNotificationPresentationOptions.sound , UNNotificationPresentationOptions.alert , UNNotificationPresentationOptions.badge])
//    }
//    
//    @available(iOS 10.0, *)
//    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//        self.store.setValueInState(value: true as NSSecureCoding, forKey: "shouldDoDaily")
//        let storyboard = UIStoryboard(name: "Splash", bundle: Bundle.main)
//        let vc = storyboard.instantiateInitialViewController()
//        self.transition(toRootViewController: vc!, animated: true)
//        
//        completionHandler()
//    }

    
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
            RSTBBooleanStepGenerator(),
            RSTBScaleStepGenerator(),
            YADLFullStepGenerator(),
            YADLSpotStepGenerator(),
            ANCAncileAuthStepGenerator(),
            ANCCoreAuthStepGenerator(),
            RSTBVisualConsentStepGenerator(),
            RSTBConsentReviewStepGenerator(),
            ANCLocationPermissionRequestStepGenerator(),
            MCRedirectLoginStepGenerator()
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
            MCDefaultResult.self
        ]
    }

}
