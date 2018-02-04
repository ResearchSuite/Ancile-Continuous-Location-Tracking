//
//  MCDefaultResult.swift
//  MCSDK
//
//  Created by James Kizer on 1/17/2018.
//

import UIKit
import ResearchSuiteResultsProcessor
//import OMHClient

open class MCDefaultResult: RSRPIntermediateResult, RSRPFrontEndTransformer {
    
    private static let supportedTypes = [
        "defaultResult"
    ]
    
    public static func supportsType(type: String) -> Bool {
        return self.supportedTypes.contains(type)
    }
    
    public class func transform(taskIdentifier: String, taskRunUUID: UUID, parameters: [String : AnyObject]) -> RSRPIntermediateResult? {
        
        guard let dataType = parameters["data_type"] as? String,
            let urlPath = parameters["url_path"] as? String else {
            return nil
        }
        
        guard let resultDict = RSRPDefaultResultHelpers.extractResults(parameters: parameters, forSerialization: true) else {
            return nil
        }
        
        let defaultResult = MCDefaultResult(
            uuid: UUID(),
            taskIdentifier: taskIdentifier,
            taskRunUUID: taskRunUUID,
            dataType: dataType,
            urlPath: urlPath,
            resultDict: resultDict)
        
        defaultResult.startDate = RSRPDefaultResultHelpers.startDate(parameters: parameters)
        defaultResult.endDate = RSRPDefaultResultHelpers.endDate(parameters: parameters)
        
        return defaultResult
        
    }
    
    public let resultDict: [String: AnyObject]
    public let urlPath: String
    
    public init(
        uuid: UUID,
        taskIdentifier: String,
        taskRunUUID: UUID,
        dataType: String,
        urlPath: String,
        resultDict: [String: AnyObject]
        ) {
        
        self.resultDict = resultDict
        self.urlPath = urlPath
        
        super.init(
            type: dataType,
            uuid: uuid,
            taskIdentifier: taskIdentifier,
            taskRunUUID: taskRunUUID
        )
    }
}
//
//extension OMHDefaultResult: OMHDataPointBuilder {
//
//    open var dataPointID: String {
//        return self.uuid.uuidString
//    }
//    
//    open var acquisitionModality: OMHAcquisitionProvenanceModality {
//        return .SelfReported
//    }
//    
//    open var acquisitionSourceCreationDateTime: Date {
//        return self.startDate ?? Date()
//    }
//    
//    open var acquisitionSourceName: String {
//        return Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
//    }
//    
//    open var body: [String: Any] {
//        return self.resultDict
//    }
//    
//}

