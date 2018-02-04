//
//  MCBackEnd.swift
//  MCSDK
//
//  Created by James Kizer on 1/17/2018.
//

import UIKit
import ResearchSuiteResultsProcessor

open class MCBackEnd: RSRPBackEnd {
    
    let manager: MCManager
    let transformers: [MCIntermediateDatapointTransformer.Type]
    
    public init(manager: MCManager,
                transformers: [MCIntermediateDatapointTransformer.Type] = []) {

        self.manager = manager
        self.transformers = transformers
    }
    
    open func add(intermediateResult: RSRPIntermediateResult) {
        for transformer in self.transformers {
            if let sample: MCSample = transformer.transform(intermediateResult: intermediateResult) {
                self.manager.addSample(sample: sample, completion: { (error) in
                    debugPrint(error)
                })
            }
        }
    }
    
}
