//
//  MCSample.swift
//  MobileCacheSDK
//
//  Created by James Kizer on 1/25/18.
//

import UIKit
import Gloss

public protocol MCSample: Gloss.Encodable, NSSecureCoding {
    func generateURL(baseURL: String) -> String
    func dataJSON() -> JSON?
    var date: Date { get }
    var dateFormatter: ISO8601DateFormatter { get }
}

extension MCSample {
    
    public var dateFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        return formatter
    }
    
    public func toJSON() -> JSON? {
        var dict: [String: Any] = [:]
        
        guard let data = self.dataJSON() else {
            return nil
        }
        
        data.keys.forEach { (key) in
            dict[key] = data[key]
        }
        
        dict["date"] = self.dateFormatter.string(from: self.date)
        
        return dict
    }
}


