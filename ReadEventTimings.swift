//
//  ReadEventTiming.swift
//  AncileContinuousLocationStudy
//
//  Created by James Kizer on 12/7/17.
//  Copyright © 2017 Christina Tsangouri. All rights reserved.
//

import UIKit
import ResearchSuiteResultsProcessor

public struct ReadEventTiming {
    let index: Int
    let duration: TimeInterval
}

extension ReadEventTiming: CSVConvertible {
    
    public static var typeString: String {
        return "ReadEventTimings"
    }
    
    public static var header: String {
        return "index,duration"
    }
    
    public static var formatter = ISO8601DateFormatter()
    
}

extension ReadEventTiming: CSVEncodable {
    public func toRecords() -> [CSVRecord] {
        let record: CSVRecord = [
            "\(self.index)",
            "\(self.duration)"
            ].joined(separator: ",")
        return [record]
    }
}
