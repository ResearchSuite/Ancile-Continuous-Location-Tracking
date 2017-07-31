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

}
