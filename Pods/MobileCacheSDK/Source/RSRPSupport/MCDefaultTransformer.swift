//
//  MCDefaultTransformer.swift
//  MobileCacheSDK
//
//  Created by James Kizer on 1/25/18.
//

import UIKit
import ResearchSuiteResultsProcessor

public class MCDefaultTransformer: MCIntermediateDatapointTransformer {
    static public func transform(intermediateResult: RSRPIntermediateResult) -> MCSample? {
        
        guard let defaultResult = intermediateResult as? MCDefaultResult else {
                return nil
        }
        
        return MCDefaultSample(urlPath: defaultResult.urlPath, data: defaultResult.resultDict as NSDictionary, date: defaultResult.startDate ?? Date())
        
    }
    
    
}
