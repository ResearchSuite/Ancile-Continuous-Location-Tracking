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
        else if !appDelegate.locationsSet {
            return "locationOnboarding"
        }
        else if !appDelegate.notificationTimeSet {
            return "notificationTime"
        }
        else {
            return nil
        }

    }

    func launchActivity() {

        guard let appDelegate = AppDelegate.appDelegate else {
            return
        }

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

        else {
            appDelegate.store.participantSince = Date()
            appDelegate.showViewController(animated: true)
        }

    }

//    func consentTask() -> (ORKTask, ORKConsentDocument)? {
//        //        let consentDocument = ANCConsentDocument()
//
//        guard let consentDocumentJSON = AppDelegate.appDelegate.taskBuilder.helper.getJson(forFilename: "consentDocument") as? JSON,
//            let consentDocType: String = "type" <~~ consentDocumentJSON,
//            let consentDocument = AppDelegate.appDelegate.taskBuilder.generateConsentDocument(
//                type: consentDocType, jsonObject: consentDocumentJSON, helper: AppDelegate.appDelegate.taskBuilder.helper) else {
//                    return nil
//        }
//
//        let visualConsentStep = ORKVisualConsentStep(identifier: "visualConsentStep", document: consentDocument)
//
//        guard let signature = consentDocument.signatures?.first else {
//            return nil
//        }
//
//        let reviewConsentStep = ORKConsentReviewStep(identifier: "consentReviewStep", signature: signature, in: consentDocument)
//
//        // In a real application, you would supply your own localized text.
//        reviewConsentStep.text = "Consent Review"
//        reviewConsentStep.reasonForConsent = "You need to consent"
//
//        return (ORKOrderedTask(identifier: "consentTask", steps: [
//            visualConsentStep,
//            reviewConsentStep
//            ]), consentDocument)
//    }





}
