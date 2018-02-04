//
//  MCLogicalLocationSample.swift
//  MobileCacheSDK
//
//  Created by James Kizer on 1/25/18.
//

import UIKit
import Gloss

public class MCLogicalLocationSample: NSObject, MCSample {
    public func dataJSON() -> JSON? {
        return [
            "location": self.location,
            "action": self.action
        ]
    }
    
    
    public func generateURL(baseURL: String) -> String {
        return baseURL + "/api/location/"
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    //DECODING
    public required init?(coder aDecoder: NSCoder) {
        guard let date: Date = aDecoder.decodeObject(of: NSDate.self, forKey: "date") as Date?,
            let location: String = aDecoder.decodeObject(of: NSString.self, forKey: "location") as String?,
            let action: String = aDecoder.decodeObject(of: NSString.self, forKey: "action") as String? else {
                return nil
        }
        
        self.date = date
        self.location = location
        self.action = action
        
        super.init()
    }
    
    //ENCODING
    private typealias CodingClosure = (String, Any)->()
    
    public func encode(with aCoder: NSCoder) {
        let closure: CodingClosure = { (key, value) in
            aCoder.encode(value, forKey: key)
        }
        
        self.encode(closure: closure)
    }
    
    public func encode(closure: (String, Any) -> ()) {
        closure("date", self.date as NSDate)
        closure("location", self.location as NSString)
        closure("action", self.action as NSString)
    }
    
    public let date: Date
    let location: String
    let action: String
    
    public init(date: Date,
                location: String,
                action: String) {
        
        
        self.date = date
        self.location = location
        self.action = action
        
        super.init()
        
    }

}
