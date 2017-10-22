//
//  SurveyOnboardingViewController.swift
//  AncileContinuousLocationStudy
//
//  Created by Christina Tsangouri on 8/2/17.
//  Copyright © 2017 Christina Tsangouri. All rights reserved.
//

import UIKit
import ResearchKit
import ResearchSuiteAppFramework
import UserNotifications

class SurveyOnboardingViewController: UIViewController {
    
    var dailyNotifSet = false
    var homeSet = false
    var workSet = false
    var dailySurveyCompleted = false
    var resultAddressWork : String = ""
    var resultAddressHome : String = ""
    var store: ANCStore!
//    var jsonObject: [String: Any]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.store = ANCStore()
        
//        var userCalendar = Calendar.current
//        userCalendar.timeZone = TimeZone(abbreviation: "EDT")!
//        
//        var fireDate = NSDateComponents()
//        
//        let hour = 6
//        let minutes = 0
//        
//        fireDate.hour = hour
//        fireDate.minute = minutes
        
        
//        self.jsonObject = [
//            "identifier": "dailyNotificationTime",
//            "type": "activity",
//            "element": [
//                "identifier":"dailyNotificationTime",
//                "type":"timePicker",
//                "title": "Daily Survey Notification",
//                "text":"Please choose when you would like to be reminded to perform your daily survey.",
//                "optional": false,
//                "default":fireDate as DateComponents
//            ]
//        ]
//        
//        let valid = JSONSerialization.isValidJSONObject(jsonObject) // true
//        NSLog(valid)
        
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
       startSurveys()
        
    }
    
    
    func startSurveys() {
        
        if !dailyNotifSet {
            self.launchDailyNotification()
        }
        else if !homeSet {
            self.launchHomeLocation()
        }
        else if !workSet {
            self.launchWorkLocation()
        }
        else if !dailySurveyCompleted {
            self.launchDailySurvey()
        }
    }
    
    func setNotification(resultAnswer: DateComponents) {
        
        var userCalendar = Calendar.current
        userCalendar.timeZone = TimeZone(abbreviation: "EDT")!
        
        var fireDate = NSDateComponents()
        
        let hour = resultAnswer.hour
        let minutes = resultAnswer.minute
        
        fireDate.hour = hour!
        fireDate.minute = minutes!
        
        ANCNotificationManager.setNotifications(fireDate: fireDate as DateComponents)
        
        self.store.setValueInState(value: String(describing:hour!) as NSSecureCoding, forKey: "notificationHour")
        self.store.setValueInState(value: String(describing:minutes!) as NSSecureCoding, forKey: "notificationMinutes")
        
    }
    
    

    func launchDailyNotification() {
        
        guard let task = AppDelegate.appDelegate.activityManager.task(for: "dailyNotificationTime"),
            let activity = AppDelegate.appDelegate.activityManager.activity(for: "dailyNotificationTime") else {
                return
        }
        
        let tvc = RSAFTaskViewController(activityUUID: UUID(), task: task, taskFinishedHandler: { [weak self] (taskViewController, reason, error) in
            
            guard reason == ORKTaskViewControllerFinishReason.completed else {
                self?.dismiss(animated: true, completion: {
                    self?.startSurveys()
                })
                return
            }
            
            let taskResult = taskViewController.result
            AppDelegate.appDelegate.resultsProcessor.processResult(taskResult: taskResult, resultTransforms: activity.resultTransforms)
            let result = taskResult.stepResult(forStepIdentifier: "dailyNotificationTime")
            let timeAnswer = result?.firstResult as? ORKTimeOfDayQuestionResult
            let resultAnswer = timeAnswer?.dateComponentsAnswer
            // ANCNotificationManager.setNotification(identifier: "WeeklyNotification", components: resultAnswer!)
            
            self?.setNotification(resultAnswer: resultAnswer!)
            
            self?.dailyNotifSet = true
            
            AppDelegate.appDelegate.resultsProcessor.processResult(taskResult: taskResult, resultTransforms: activity.resultTransforms)
            
            self?.dismiss(animated: true, completion: {
                self?.startSurveys()
                
            })
            
        })
        
        self.present(tvc, animated: true, completion: nil)
       
        
    }
    
    func launchHomeLocation() {
        
        guard let task = AppDelegate.appDelegate.activityManager.task(for: "homeLocation"),
            let activity = AppDelegate.appDelegate.activityManager.activity(for: "homeLocation") else {
                return
        }
        
        let tvc = RSAFTaskViewController(activityUUID: UUID(), task: task, taskFinishedHandler: { [weak self] (taskViewController, reason, error) in
            
            guard reason == ORKTaskViewControllerFinishReason.completed else {
                self?.dismiss(animated: true, completion: {
                    self?.startSurveys()
                })
                
                return
            }
            
            let taskResult = taskViewController.result
            
            self?.homeSet = true
            
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
            
            
            self?.dismiss(animated: true, completion: {
                AppDelegate.appDelegate.updateMonitoredRegions(regionChanged: "onboarding_home")
                self?.startSurveys()
                
            })
            
        })
        
        AppDelegate.appDelegate.locationManager.requestAlwaysAuthorization()
        
        
        self.present(tvc, animated: true, completion: nil)
        
    }
    
    
    func launchWorkLocation() {
        
        guard let task = AppDelegate.appDelegate.activityManager.task(for: "workLocation"),
            let activity = AppDelegate.appDelegate.activityManager.activity(for: "workLocation") else {
                return
        }
        
        let tvc = RSAFTaskViewController(activityUUID: UUID(), task: task, taskFinishedHandler: { [weak self] (taskViewController, reason, error) in
            
            guard reason == ORKTaskViewControllerFinishReason.completed else {
                self?.dismiss(animated: true, completion: {
                    self?.startSurveys()
                })
                
                return
            }
            
            let taskResult = taskViewController.result
            
            self?.workSet = true
            
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
            
            
            self?.dismiss(animated: true, completion: {
                AppDelegate.appDelegate.updateMonitoredRegions(regionChanged: "onboarding_work")
                self?.startSurveys()
                
            })
            
        })
        
        self.present(tvc, animated: true, completion: nil)
        
    }
    
    
    func launchDailySurvey() {
        
        guard let task = AppDelegate.appDelegate.activityManager.task(for: "dailySurvey"),
            let activity = AppDelegate.appDelegate.activityManager.activity(for: "dailySurvey") else {
                return
        }
        
        let tvc = RSAFTaskViewController(activityUUID: UUID(), task: task, taskFinishedHandler: { [weak self] (taskViewController, reason, error) in
            
            guard reason == ORKTaskViewControllerFinishReason.completed else {
                self?.dismiss(animated: true, completion: {
                    self?.startSurveys()
                })
                
                return
            }
            
            let taskResult = taskViewController.result
            
            self?.dailySurveyCompleted = true
            
            AppDelegate.appDelegate.resultsProcessor.processResult(taskResult: taskResult, resultTransforms: activity.resultTransforms)
            
            self?.dismiss(animated: true, completion: {
                let storyboard = UIStoryboard(name: "Splash", bundle: nil)
                let vc = storyboard.instantiateInitialViewController()
                AppDelegate.appDelegate.transition(toRootViewController: vc!, animated: true)
                
            })
            
        })
        
        self.present(tvc, animated: true, completion: nil)
    
        
    }
 
    

    

}
