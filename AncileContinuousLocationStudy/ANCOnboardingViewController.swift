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
import Gloss

open class ANCOnboardingViewController: UIViewController {
    
    var dailyNotificationSet = false
    var weeklyNotificationSet = false
    var homeLocationSet = false
    var workLocationSet = false
    var resultAddressWork : String = ""
    var resultAddressHome : String = ""
    var store: ANCStore!
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.store = ANCStore()
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func getStartedTapped(_ sender: Any) {
        
        self.launchActivity()
        
    }
    
    private func getNextActivityID() -> String? {
        
        guard let appDelegate = AppDelegate.appDelegate else {
            return nil
        }
        
        if !appDelegate.isEligible {
            return "eligibility"
        }
        else if !appDelegate.isConsented {
            return "consent"
        }
        else if !appDelegate.isSignedIn || !appDelegate.isPasscodeSet {
            return "authFlow"
        }
        else if !appDelegate.notificationTimeSet {
            return "notificationTime"
        }
        else {
            return nil
        }
    
    }
    
    func launchActivity() {
        
        if let nextActivityID = self.getNextActivityID() {
            
            guard let task = AppDelegate.appDelegate.activityManager.task(for: nextActivityID) else {
                return
            }
            
            let tvc = RSAFTaskViewController(activityUUID: UUID(), task: task, taskFinishedHandler: { [weak self] (taskViewController, reason, error) in
                
                guard reason == ORKTaskViewControllerFinishReason.completed,
                    let vc = self else {
                    self?.dismiss(animated: true, completion: nil)
                    return
                }
                
                let taskResult = taskViewController.result
                //view controller, taskResult, handle activity completion
                ANCActivityManager.handleActivityResult(viewController: vc, taskResult: taskResult, completion: { success in
                    self?.dismiss(animated: true, completion: {
                        if success {
                            self?.launchActivity()
                        }
                    })
                })
                
            })
            
            self.present(tvc, animated: true, completion: nil)
        }
        
        guard let appDelegate = AppDelegate.appDelegate else {
            return
        }
        
        if !appDelegate.isEligible {
            
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
                
                appDelegate.store.isEligible = true
                self?.dismiss(animated: true, completion: {
                    if eligible {
                        self?.launchActivity()
                    }
                })
                
            })
            
            self.present(tvc, animated: true, completion: nil)
        }
        else if !appDelegate.isConsented {
            
            guard let task = AppDelegate.appDelegate.activityManager.task(for: "consent") else {
                return
            }
            
            guard let consentDocumentJSON = AppDelegate.appDelegate.taskBuilder.helper.getJson(forFilename: "consentDocument") as? JSON,
                let consentDocType: String = "type" <~~ consentDocumentJSON,
                let consentDocument = AppDelegate.appDelegate.taskBuilder.generateConsentDocument(
                    type: consentDocType, jsonObject: consentDocumentJSON, helper: AppDelegate.appDelegate.taskBuilder.helper) else {
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
                
                consentSignature.apply(to: consentDocument)
                
                consentDocument.makePDF(completionHandler: { (data, error) in
                    
                    if error == nil {
                        guard let pdfData = data,
                            let documentsPathString = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first else {
                                return
                        }
                        
                        let documentsPath: URL = URL(fileURLWithPath: documentsPathString)
                        let pathComponent: String = "\(taskViewController.taskRunUUID.uuidString).pdf"
                        let fileURL: URL = documentsPath.appendingPathComponent(pathComponent)
                        
                        do {
                            try pdfData.write(to: fileURL, options: [Data.WritingOptions.completeFileProtection , Data.WritingOptions.atomic])
                        } catch let error as NSError {
                            print(error.localizedDescription)
                        }
                        
                        debugPrint("Wrote PDF to \(fileURL.absoluteString)")
                        
                        //save file URL in state
                        AppDelegate.appDelegate.store.consentDocURL = fileURL
                    }
                    
                    self?.dismiss(animated: true, completion: {
                        if consentSignature.consented {
                            self?.launchActivity()
                        }
                    })
                    
                })
                
            })
            
            self.present(tvc, animated: true, completion: nil)
            
        }
            
        else if !appDelegate.isSignedIn || !appDelegate.isPasscodeSet {
            
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
                    
                    if let authToken = appDelegate.ancileClient.authToken,
                        appDelegate.isConsented,
                        let consentDocURL = AppDelegate.appDelegate.store.consentDocURL {
                        
                        appDelegate.ancileClient.postConsent(token: authToken, fileName: "dont_care", fileURL: consentDocURL, completion: { (consented, error) in
                            self?.dismiss(animated: true, completion: {
                                self?.launchActivity()
                            })
                        })
                        
                    }
                    else {
                        self?.dismiss(animated: true, completion: {
                            self?.launchActivity()
                        })
                    }
                    
                    
                    
                })
                
                self.present(tvc, animated: true, completion: nil)
                
            })
            
        }
            
        else if !appDelegate.notificationTimeSet {
            guard let task = AppDelegate.appDelegate.activityManager.task(for: "notificationTime") else {
                return
            }
            
            let tvc = RSAFTaskViewController(activityUUID: UUID(), task: task, taskFinishedHandler: { [weak self] (taskViewController, reason, error) in
                
                guard reason == ORKTaskViewControllerFinishReason.completed else {
                    self?.dismiss(animated: true, completion: nil)
                    return
                }
                
                let taskResult = taskViewController.result
                
                print(taskResult)
                
                guard let stepResult = taskResult.result(forIdentifier: "notificationTime") as? ORKStepResult,
                    let timeResult = stepResult.result(forIdentifier: "notificationTime") as? ORKTimeOfDayQuestionResult,
                    let timeComponents = timeResult.dateComponentsAnswer else {
                        self?.dismiss(animated: true, completion: nil)
                        return
                }
                
                AppDelegate.appDelegate.store.notificationTime = timeComponents
                ANCNotificationManager.setNotifications()
                ANCNotificationManager.printPendingNotifications()
                
                self?.dismiss(animated: true, completion: {
                    self?.launchActivity()
                })
                
                
                
            })
            
            self.present(tvc, animated: true, completion: nil)
        }
            
        else {
            AppDelegate.appDelegate.store.participantSince = Date()
            appDelegate.showViewController(animated: true)
        }
        
        
    }
    
    
    
    func consentTask() -> (ORKTask, ORKConsentDocument)? {
        //        let consentDocument = ANCConsentDocument()
        
        guard let consentDocumentJSON = AppDelegate.appDelegate.taskBuilder.helper.getJson(forFilename: "consentDocument") as? JSON,
            let consentDocType: String = "type" <~~ consentDocumentJSON,
            let consentDocument = AppDelegate.appDelegate.taskBuilder.generateConsentDocument(
                type: consentDocType, jsonObject: consentDocumentJSON, helper: AppDelegate.appDelegate.taskBuilder.helper) else {
                    return nil
        }
        
        let visualConsentStep = ORKVisualConsentStep(identifier: "visualConsentStep", document: consentDocument)
        
        guard let signature = consentDocument.signatures?.first else {
            return nil
        }
        
        let reviewConsentStep = ORKConsentReviewStep(identifier: "consentReviewStep", signature: signature, in: consentDocument)
        
        // In a real application, you would supply your own localized text.
        reviewConsentStep.text = "Consent Review"
        reviewConsentStep.reasonForConsent = "You need to consent"
        
        return (ORKOrderedTask(identifier: "consentTask", steps: [
            visualConsentStep,
            reviewConsentStep
            ]), consentDocument)
    }
    

    

    
}

