//
//  ANCActivityManager.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 7/10/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

import UIKit
import Gloss
import ResearchSuiteTaskBuilder
import ResearchSuiteResultsProcessor
import ResearchKit
import CoreLocation

class ANCActivityManager: NSObject {
    
    let activityMap: [String: ANCActivity]
    let taskBuilder: RSTBTaskBuilder
    
    init?(activityFilename: String, taskBuilder: RSTBTaskBuilder) {
        
        guard let activityFileJSON = ANCActivityManager.getJson(forFilename: activityFilename),
            let activitiesJSON: [JSON] = "activities" <~~ activityFileJSON else {
            return nil
        }
        
        var activityMap: [String: ANCActivity] = [:]
        
        activitiesJSON
            .flatMap { ANCActivity(json: $0) }
            .forEach { (activity) in
                activityMap[activity.identifier] = activity
        }
        
        self.activityMap = activityMap
        
        self.taskBuilder = taskBuilder
        
    }
    
    public func activity(for identifier: String) -> ANCActivity? {
        return self.activityMap[identifier]
    }
    
    public func task(for activityIdentifier: String) -> ORKTask? {
        guard let activity = self.activity(for: activityIdentifier),
            let steps = self.taskBuilder.steps(forElement: activity.element as JsonElement) else {
                return nil
        }
        
        return ORKOrderedTask(identifier: activity.identifier, steps: steps)
    }
    
//    public func task(for activityJson: JsonElement) -> ORKTask? {
//        guard let steps = self.taskBuilder.steps(forElement: activityJson as JsonElement) else {
//                return nil
//        }
//        
//        return ORKOrderedTask(identifier: "ac", steps: steps)
//    }
    
    static func getJson(forFilename filename: String, inBundle bundle: Bundle = Bundle.main) -> JSON? {
        
        guard let filePath = bundle.path(forResource: filename, ofType: "json")
            else {
                assertionFailure("unable to locate file \(filename)")
                return nil
        }
        
        guard let fileContent = try? Data(contentsOf: URL(fileURLWithPath: filePath))
            else {
                assertionFailure("Unable to create NSData with content of file \(filePath)")
                return nil
        }
        
        let json = try! JSONSerialization.jsonObject(with: fileContent, options: JSONSerialization.ReadingOptions.mutableContainers)
        
        return json as? JSON
    }
    
    public static func handleActivityResult(viewController: UIViewController, taskResult: ORKTaskResult, completion: @escaping (Bool) ->()) {
        
        guard let appDelegate = AppDelegate.appDelegate else {
            return
        }
        
        if let activity = AppDelegate.appDelegate.activityManager.activity(for: taskResult.identifier) {
            AppDelegate.appDelegate.resultsProcessor.processResult(taskResult: taskResult, resultTransforms: activity.resultTransforms)
        }
        
        switch taskResult.identifier {
        case "eligibility":
            guard let stepResult = taskResult.result(forIdentifier: "eligibility") as? ORKStepResult,
                let ageResult = stepResult.result(forIdentifier: "age") as? ORKBooleanQuestionResult,
                let eligible = ageResult.booleanAnswer?.boolValue else {
                    completion(false)
                    return
            }
            
            appDelegate.store.isEligible = eligible
            completion(eligible)
            
        case "consent":
            guard let consentDocumentJSON = AppDelegate.appDelegate.taskBuilder.helper.getJson(forFilename: "consentDocument") as? JSON,
                let consentDocType: String = "type" <~~ consentDocumentJSON,
                let consentDocument = AppDelegate.appDelegate.taskBuilder.generateConsentDocument(
                    type: consentDocType, jsonObject: consentDocumentJSON, helper: AppDelegate.appDelegate.taskBuilder.helper) else {
                        completion(false)
                        return
            }
            
            guard let stepResult = taskResult.result(forIdentifier: "consentReviewStep") as? ORKStepResult,
                let consentSignature = stepResult.firstResult as? ORKConsentSignatureResult else {
                    completion(false)
                    return
            }
            
            consentSignature.apply(to: consentDocument)
            
            //possibly check to see if we can offload this to another thread
            consentDocument.makePDF(completionHandler: { (data, error) in
                
                if error == nil {
                    guard let pdfData = data,
                        let documentsPathString = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first else {
                            completion(false)
                            return
                    }
                    
                    let documentsPath: URL = URL(fileURLWithPath: documentsPathString)
                    let pathComponent: String = "\(taskResult.taskRunUUID.uuidString).pdf"
                    let fileURL: URL = documentsPath.appendingPathComponent(pathComponent)
                    
                    do {
                        try pdfData.write(to: fileURL, options: [Data.WritingOptions.completeFileProtection , Data.WritingOptions.atomic])
                    } catch let error as NSError {
                        print(error.localizedDescription)
                        completion(false)
                        return
                    }
                    
                    debugPrint("Wrote PDF to \(fileURL.absoluteString)")
                    
                    //save file URL in state
                    AppDelegate.appDelegate.store.consentDocURL = fileURL
                }
                
                completion(consentSignature.consented)
                return
                
            })
            
        case "authFlow":
            if let authToken = appDelegate.ancileClient.authToken,
                appDelegate.isConsented,
                let consentDocURL = AppDelegate.appDelegate.store.consentDocURL {
                
                appDelegate.ancileClient.postConsent(token: authToken, fileName: "dont_care", fileURL: consentDocURL, completion: { (consented, error) in
                    completion(true)
                    return
                })
                
            }
            else {
                completion(true)
                return
            }
            
        case "locationOnboarding":
            fallthrough
        case "homeLocation":
            fallthrough
        case "workLocation":
            if let stepResult = taskResult.result(forIdentifier: "homeLocation") as? ORKStepResult,
                let locationResult = stepResult.firstResult as? ORKLocationQuestionResult,
                let location = locationResult.locationAnswer {
                //set location, start monitoring
                appDelegate.locationManager.home = location.coordinate
            }
            
            if let stepResult = taskResult.result(forIdentifier: "workLocation") as? ORKStepResult,
                let locationResult = stepResult.firstResult as? ORKLocationQuestionResult,
                let location = locationResult.locationAnswer {
                //set location, start monitoring
                appDelegate.locationManager.work = location.coordinate
            }
            
            
            //TODO: FIX THIS
            //this is not working due to not persisting the home and work locations
            if let home = appDelegate.locationManager.home,
                let work = appDelegate.locationManager.work {
                
                let homeLocation = CLLocation(latitude: home.latitude, longitude: home.longitude)
                let workLocation = CLLocation(latitude: work.latitude, longitude: work.longitude)
                
                let distance = homeLocation.distance(from: workLocation)
                
                let distanceSample = DistanceSample(
                    uuid: UUID(),
                    taskIdentifier: taskResult.identifier,
                    taskRunUUID: taskResult.taskRunUUID,
                    sampleDescription: "distance between home and work",
                    distance: distance
                )
                
                appDelegate.ohmageManager.addDatapoint(datapoint: distanceSample, completion: { (error) in
                    completion(true)
                })
            }
            else {
                completion(false)
            }
            
            appDelegate.store.locationsSet = true
            
            
        case "dailySurvey":
            
            AppDelegate.appDelegate.store.lastSurveyCompletionTime = Date()
            completion(true)
            
            break;
            
        case "notificationTime":
            guard let stepResult = taskResult.result(forIdentifier: "notificationTime") as? ORKStepResult,
                let timeResult = stepResult.result(forIdentifier: "notificationTime") as? ORKTimeOfDayQuestionResult,
                let timeComponents = timeResult.dateComponentsAnswer else {
                    completion(false)
                    return
            }
            
            AppDelegate.appDelegate.store.notificationTime = timeComponents
            ANCNotificationManager.setNotifications()
            ANCNotificationManager.printPendingNotifications()
            
            completion(true)
            return
            
            
        default:
            completion(false)
        }
        
        completion(true)
    }

}
