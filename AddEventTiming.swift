//
//  EventTiming.swift
//  AncileContinuousLocationStudy
//
//  Created by James Kizer on 12/7/17.
//  Copyright © 2017 Christina Tsangouri. All rights reserved.
//

import UIKit
import ResearchSuiteResultsProcessor

public struct AddEventTiming {
    let uuid: UUID
    let index: Int
    let duration: TimeInterval
}

extension AddEventTiming: CSVConvertible {
    
    public static var typeString: String {
        return "AddEventTiming"
    }
    
    public static var header: String {
        return "index,uuid,duration"
    }
    
    public static var formatter = ISO8601DateFormatter()

}

extension AddEventTiming: CSVEncodable {
    public func toRecords() -> [CSVRecord] {
        let record: CSVRecord = [
            "\(self.index)",
            self.uuid.uuidString,
            "\(self.duration)"
        ].joined(separator: ",")
        return [record]
    }
}
