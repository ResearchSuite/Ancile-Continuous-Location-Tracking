//
//  MCIntermediateDatapointTransformer.swift
//  MCSDK
//
//  Created by James Kizer on 1/17/2018.
//

import UIKit
import ResearchSuiteResultsProcessor

public protocol MCIntermediateDatapointTransformer {
    static func transform(intermediateResult: RSRPIntermediateResult) -> MCSample?
}

