//
//  LocationEvent.swift
//  AncileContinuousLocationStudy
//
//  Created by James Kizer on 11/16/17.
//  Copyright © 2017 Christina Tsangouri. All rights reserved.
//

import UIKit
import ResearchSuiteResultsProcessor
import OMHClient

public struct LocationEvent: Codable {
    
    let uuid: UUID
    let identifier: String
    let action: LocationEventAction
    let timestamp: Date

    public static var formatter = ISO8601DateFormatter()
}

extension LocationEvent: CSVConvertible {
    public static var typeString: String {
        return "LocationEvent"
    }
    
    public static var header: String {
        return "uuid,timestamp,identifier,action"
    }
}

extension LocationEvent: CSVEncodable {
    public func toRecords() -> [CSVRecord] {
        let record: CSVRecord = [
            self.uuid.uuidString,
            LocationEvent.formatter.string(from: self.timestamp),
            self.identifier,
            self.action.rawValue
            ].joined(separator: ",")
        return [record]
    }
}

extension LocationEvent: CSVDecodable {
    
    public init?(record: CSVRecord) {
        
        let items = record.split(separator: ",")
        
        guard items.count == 4 else {
            return nil
        }
        
        let uuidString = String(items[0])
        let timestampString = String(items[1])
        let identifier = String(items[2])
        let actionString = String(items[3])
        
        guard let uuid = UUID(uuidString: uuidString),
            let timestamp = LocationEvent.formatter.date(from: timestampString),
            let action = LocationEventAction(rawValue: actionString) else {
                return nil
        }
        
        self.init(uuid: uuid, identifier: identifier, action: action, timestamp: timestamp)
        
    }
}

extension LocationEvent: OMHDataPointBuilder {
    public var schema: OMHSchema {
        return OMHSchema(
            name: "logical-location",
            version: "1.0",
            namespace: "cornell")
    }
    
    public var creationDateTime: Date {
        return self.timestamp
    }
    
    public var dataPointID: String {
        return self.uuid.uuidString
    }
    
    public var acquisitionModality: OMHAcquisitionProvenanceModality? {
        return .SelfReported
    }
    
    public var acquisitionSourceCreationDateTime: Date? {
        return self.timestamp
    }
    
    public var acquisitionSourceName: String? {
        return Bundle.main.infoDictionary![kCFBundleNameKey as String] as? String
    }
    
    public var body: [String: Any] {
        return [
            "location": self.identifier,
            "action": self.action.rawValue,
            "effective_time_frame": [
                "date_time": LocationEvent.formatter.string(from: self.timestamp)
            ]
        ]
    }
    
}

