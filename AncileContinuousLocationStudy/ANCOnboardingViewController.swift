//
//  ANCOnboardingViewController.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 7/10/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

import UIKit
import ResearchSuiteAppFramework
import ResearchKit
import UserNotifications

open class ANCOnboardingViewController: UIViewController {
    
    // TODO: set these all to false again!!!!
    var eligible = false
    var consented = false
    var authenticated = true
    var notificationSet = false
    var homeLocationSet = false
    var workLocationSet = false
    var resultAddressWork : String = ""
    var resultAddressHome : String = ""
    var store: ANCStore!

    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.store = ANCStore()

        // Do any additional setup after loading the view.
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func getStartedTapped(_ sender: Any) {
//        let url: URL = (AppDelegate.appDelegate.client?.authURL)!
//        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        
        self.launchActivity()
        
    }
    
    func chooseActivity() -> String? {
        if !eligible {
            return "eligibility"
        }
    
        return "authFlow"
    }
    
    func launchActivity() {
        
        if !eligible {
            
            guard let task = AppDelegate.appDelegate.activityManager.task(for: "eligibility") else {
                return
            }
            
            let tvc = RSAFTaskViewController(activityUUID: UUID(), task: task, taskFinishedHandler: { [weak self] (taskViewController, reason, error) in
                
                guard reason == ORKTaskViewControllerFinishReason.completed else {
                    self?.dismiss(animated: true, completion: nil)
                    return
                }
                
                let taskResult = taskViewController.result
                
                guard let stepResult = taskResult.result(forIdentifier: "eligibility") as? ORKStepResult,
                    let ageResult = stepResult.result(forIdentifier: "age") as? ORKBooleanQuestionResult,
                    let eligible = ageResult.booleanAnswer?.boolValue else {
                        self?.dismiss(animated: true, completion: nil)
                        return
                }
                
                self?.eligible = eligible
                self?.dismiss(animated: true, completion: {
                    if eligible {
                        self?.launchActivity()
                    }
                })
                
            })
            
            self.present(tvc, animated: true, completion: nil)
        }
        else if !consented {
            
            guard let task = self.consentTask() else {
                return
            }
            
            let tvc = RSAFTaskViewController(activityUUID: UUID(), task: task, taskFinishedHandler: { [weak self] (taskViewController, reason, error) in
                
                guard reason == ORKTaskViewControllerFinishReason.completed else {
                    self?.dismiss(animated: true, completion: nil)
                    return
                }
                
                let taskResult = taskViewController.result
                
                guard let stepResult = taskResult.result(forIdentifier: "consentReviewStep") as? ORKStepResult,
                    let consentSignature = stepResult.firstResult as? ORKConsentSignatureResult else {
                        self?.dismiss(animated: true, completion: nil)
                        return
                }
                
                self?.consented = consentSignature.consented
                
                self?.dismiss(animated: true, completion: {
                    if consentSignature.consented {
                        self?.launchActivity()
                    }
                })
                
                
                
            })
            
            self.present(tvc, animated: true, completion: nil)
            
        }
        
        else if !authenticated {
            
            guard let appDelegate = (UIApplication.shared.delegate as? AppDelegate),
                let ohmageClient = appDelegate.ohmageManager else {
                    return
            }
            
            ohmageClient.signOut(completion: { (error) in
                
                guard let task = AppDelegate.appDelegate.activityManager.task(for: "authFlow") else {
                    return
                }
                
                let tvc = RSAFTaskViewController(activityUUID: UUID(), task: task, taskFinishedHandler: { [weak self] (taskViewController, reason, error) in
                    
                    guard reason == ORKTaskViewControllerFinishReason.completed else {
                        self?.dismiss(animated: true, completion: nil)
                        return
                    }
                    
                    let taskResult = taskViewController.result
                    
                    //                guard let stepResult = taskResult.result(forIdentifier: "eligibility") as? ORKStepResult,
                    //                    let ageResult = stepResult.result(forIdentifier: "age") as? ORKBooleanQuestionResult,
                    //                    let eligible = ageResult.booleanAnswer?.boolValue else {
                    //                        self?.dismiss(animated: true, completion: nil)
                    //                        return
                    //                }
                    //
                    //                self?.eligible = eligible
                    
                    self?.authenticated = true
                    
                    if let consented = self?.consented,
                        let appDelegate = (UIApplication.shared.delegate as? AppDelegate),
                        let authToken = appDelegate.ancileClient.authToken {
                        if consented {
                            appDelegate.ancileClient.postConsent(token: authToken, completion: { (consented, error) in
                                
                            })
                        }
                        
                    }
                    
                    self?.dismiss(animated: true, completion: {
                        
                        self?.launchActivity()
                    })
                    
                })
                
                self.present(tvc, animated: true, completion: nil)
                
            })
            
            
        }
        else if !notificationSet {
            guard let task = AppDelegate.appDelegate.activityManager.task(for: "notificationTime"),
                let activity = AppDelegate.appDelegate.activityManager.activity(for: "notificationTime")else {
                return
            }
            
            let tvc = RSAFTaskViewController(activityUUID: UUID(), task: task, taskFinishedHandler: { [weak self] (taskViewController, reason, error) in
                
                guard reason == ORKTaskViewControllerFinishReason.completed else {
                    self?.dismiss(animated: true, completion: nil)
                    return
                }
                
                self?.notificationSet = true
                
                let taskResult = taskViewController.result
                AppDelegate.appDelegate.resultsProcessor.processResult(taskResult: taskResult, resultTransforms: activity.resultTransforms)
                let result = taskResult.stepResult(forStepIdentifier: "notificationTime")
                let timeAnswer = result?.firstResult as? ORKTimeOfDayQuestionResult
                let resultAnswer = timeAnswer?.dateComponentsAnswer
                self?.setNotification(resultAnswer: resultAnswer!)
                
                self?.dismiss(animated: true, completion: {
                    self?.launchActivity()
                })
                
            })
            
            self.present(tvc, animated: true, completion: nil)
        }
        else if !homeLocationSet {
            guard let task = AppDelegate.appDelegate.activityManager.task(for: "homeLocation"),
                let activity = AppDelegate.appDelegate.activityManager.activity(for: "homeLocation") else {
                return
            }
            
            let tvc = RSAFTaskViewController(activityUUID: UUID(), task: task, taskFinishedHandler: { [weak self] (taskViewController, reason, error) in
                
                guard reason == ORKTaskViewControllerFinishReason.completed else {
                    self?.dismiss(animated: true, completion: nil)
                    return
                }
                
                let taskResult = taskViewController.result
                AppDelegate.appDelegate.resultsProcessor.processResult(taskResult: taskResult, resultTransforms: activity.resultTransforms)
                
                let resultHome = taskResult.stepResult(forStepIdentifier: "homeLocation")
                let locationAnswerHome = resultHome?.firstResult as? ORKLocationQuestionResult
                let resultCoordHome = locationAnswerHome?.locationAnswer?.coordinate
                let resultRegionHome = locationAnswerHome?.locationAnswer?.region
                var resultDictionaryHome = locationAnswerHome?.locationAnswer?.addressDictionary
                
                self?.resultAddressHome = ""
                var resultAddressPartsHome : [String] = []
                
                if resultDictionaryHome?.index(forKey: "Name") != nil {
                    let name = resultDictionaryHome?["Name"] as! String
                    resultAddressPartsHome.append(name)
                }
                if resultDictionaryHome?.index(forKey: "City") != nil {
                    let city = resultDictionaryHome?["City"] as! String
                    resultAddressPartsHome.append(",")
                    resultAddressPartsHome.append(" ")
                    resultAddressPartsHome.append(city)
                }
                if resultDictionaryHome?.index(forKey: "State") != nil {
                    let state = resultDictionaryHome?["State"] as! String
                    resultAddressPartsHome.append(",")
                    resultAddressPartsHome.append(" ")
                    resultAddressPartsHome.append(state)
                }
                if resultDictionaryHome?.index(forKey: "ZIP") != nil {
                    let zip = resultDictionaryHome?["ZIP"] as! String
                    resultAddressPartsHome.append(",")
                    resultAddressPartsHome.append(" ")
                    resultAddressPartsHome.append(zip)
                    
                }
                
                
                for i in resultAddressPartsHome {
                    self?.resultAddressHome = (self?.resultAddressHome)! + i
                }
                
                
                self?.store.setValueInState(value: self!.resultAddressHome as NSSecureCoding , forKey: "home_location")
                
                self?.store.setValueInState(value: resultCoordHome!.latitude as NSSecureCoding, forKey: "home_coordinate_lat")
                self?.store.setValueInState(value: resultCoordHome!.longitude as NSSecureCoding, forKey: "home_coordinate_long")
                
                self?.homeLocationSet = true
                self?.dismiss(animated: true, completion: {
                    AppDelegate.appDelegate.updateMonitoredRegions(regionChanged: "onboarding_home")
                    self?.launchActivity()
                })
                
            })
            
            self.present(tvc, animated: true, completion: nil)
        }
        else if !workLocationSet {
            guard let task = AppDelegate.appDelegate.activityManager.task(for: "workLocation"),
                let activity = AppDelegate.appDelegate.activityManager.activity(for: "workLocation") else {
                return
            }
            
            let tvc = RSAFTaskViewController(activityUUID: UUID(), task: task, taskFinishedHandler: { [weak self] (taskViewController, reason, error) in
                
                guard reason == ORKTaskViewControllerFinishReason.completed else {
                    self?.dismiss(animated: true, completion: nil)
                    return
                }
                
                let taskResult = taskViewController.result
                AppDelegate.appDelegate.resultsProcessor.processResult(taskResult: taskResult, resultTransforms: activity.resultTransforms)
                
                let resultWork = taskResult.stepResult(forStepIdentifier: "workLocation")
                let locationAnswerWork = resultWork?.firstResult as? ORKLocationQuestionResult
                let resultCoordWork = locationAnswerWork?.locationAnswer?.coordinate
                let resultRegionWork = locationAnswerWork?.locationAnswer?.region
                var resultDictionaryWork = locationAnswerWork?.locationAnswer?.addressDictionary
                
                self?.resultAddressWork = ""
                var resultAddressPartsWork : [String] = []
                
                if resultDictionaryWork?.index(forKey: "Name") != nil {
                    let name = resultDictionaryWork?["Name"] as! String
                    resultAddressPartsWork.append(name)
                }
                if resultDictionaryWork?.index(forKey: "City") != nil {
                    let city = resultDictionaryWork?["City"] as! String
                    resultAddressPartsWork.append(",")
                    resultAddressPartsWork.append(" ")
                    resultAddressPartsWork.append(city)
                }
                if resultDictionaryWork?.index(forKey: "State") != nil {
                    let state = resultDictionaryWork?["State"] as! String
                    resultAddressPartsWork.append(",")
                    resultAddressPartsWork.append(" ")
                    resultAddressPartsWork.append(state)
                }
                if resultDictionaryWork?.index(forKey: "ZIP") != nil {
                    let zip = resultDictionaryWork?["ZIP"] as! String
                    resultAddressPartsWork.append(",")
                    resultAddressPartsWork.append(" ")
                    resultAddressPartsWork.append(zip)
                    
                }
                
                
                for i in resultAddressPartsWork {
                    self?.resultAddressWork = (self?.resultAddressWork)! + i
                }
                
                self?.store.setValueInState(value: self!.resultAddressWork as NSSecureCoding , forKey: "work_location")
                
                self?.store.setValueInState(value: resultCoordWork!.latitude as NSSecureCoding, forKey: "work_coordinate_lat")
                self?.store.setValueInState(value: resultCoordWork!.longitude as NSSecureCoding, forKey: "work_coordinate_long")
                
                
                self?.workLocationSet = true
                self?.dismiss(animated: true, completion: {
                    AppDelegate.appDelegate.updateMonitoredRegions(regionChanged: "onboarding_work")
                    self?.launchActivity()
                })
                
            })
            
            self.present(tvc, animated: true, completion: nil)
        }
            
        else {
            
            guard let task = AppDelegate.appDelegate.activityManager.task(for: "weeklySurvey"),
                let activity = AppDelegate.appDelegate.activityManager.activity(for: "weeklySurvey") else {
                return
            }
            
            let tvc = RSAFTaskViewController(activityUUID: UUID(), task: task, taskFinishedHandler: { [weak self] (taskViewController, reason, error) in
                
                guard reason == ORKTaskViewControllerFinishReason.completed else {
                    self?.dismiss(animated: true, completion: nil)
                    return
                }
                
                let taskResult = taskViewController.result
                
                AppDelegate.appDelegate.resultsProcessor.processResult(taskResult: taskResult, resultTransforms: activity.resultTransforms)

                self?.dismiss(animated: true, completion: {
                    let storyboard = UIStoryboard(name: "Splash",bundle: Bundle.main)
                    let vc = storyboard.instantiateInitialViewController()
                    AppDelegate.appDelegate.transition(toRootViewController: vc!, animated: true)
                })
                
            })
            
            self.present(tvc, animated: true, completion: nil)
            
        }
        
        
    }
    
    func consentTask() -> ORKTask? {
        let consentDocument = ANCConsentDocument()
        let visualConsentStep = ORKVisualConsentStep(identifier: "visualConsentStep", document: consentDocument)
        
        guard let signature = consentDocument.signatures?.first else {
            return nil
        }
        
        let reviewConsentStep = ORKConsentReviewStep(identifier: "consentReviewStep", signature: signature, in: consentDocument)
        
        // In a real application, you would supply your own localized text.
        reviewConsentStep.text = "Consent Review"
        reviewConsentStep.reasonForConsent = "You need to consent"
        
        return ORKOrderedTask(identifier: "consentTask", steps: [
            visualConsentStep,
            reviewConsentStep
            ])
    }
    
    
    func setNotification(resultAnswer: DateComponents) {
        
        var userCalendar = Calendar.current
        userCalendar.timeZone = TimeZone(abbreviation: "EDT")!
        
        var fireDate = NSDateComponents()
        
        let hour = resultAnswer.hour
        let minutes = resultAnswer.minute
        
        fireDate.hour = hour!
        fireDate.minute = minutes!
        
        self.store.setValueInState(value: String(describing:hour!) as NSSecureCoding, forKey: "notificationHour")
        self.store.setValueInState(value: String(describing:minutes!) as NSSecureCoding, forKey: "notificationMinutes")
        
        
        if #available(iOS 10.0, *) {
            let content = UNMutableNotificationContent()
            content.title = "Ancile Study"
            content.body = "It's time to complete your Ancile Daily Survey"
            content.sound = UNNotificationSound.default()
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: fireDate as DateComponents,
                                                        repeats: true)
            
            let identifier = "UYLLocalNotification"
            let request = UNNotificationRequest(identifier: identifier,
                                                content: content, trigger: trigger)
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            AppDelegate.appDelegate?.center.add(request, withCompletionHandler: { (error) in
                if let error = error {
                    // Something went wrong
                }
            })
            
        } else {
            // Fallback on earlier versions
            
            let dateToday = Date()
            let day = userCalendar.component(.day, from: dateToday)
            let month = userCalendar.component(.month, from: dateToday)
            let year = userCalendar.component(.year, from: dateToday)
            
            fireDate.day = day
            fireDate.month = month
            fireDate.year = year
            
            let fireDateLocal = userCalendar.date(from:fireDate as DateComponents)
            
            let localNotification = UILocalNotification()
            localNotification.fireDate = fireDateLocal
            localNotification.alertBody = "It's time to complete your Ancile Daily Survey"
            localNotification.timeZone = TimeZone(abbreviation: "EDT")!
            //set the notification
            UIApplication.shared.scheduleLocalNotification(localNotification)
        }
        
        
    }


}
