//
//  MCDistanceSample.swift
//  MobileCacheSDK
//
//  Created by James Kizer on 1/25/18.
//

import UIKit
import Gloss

public class MCDistanceSample: NSObject, MCSample {
    
    public func dataJSON() -> JSON? {
        return [
            "description": self.data_description,
            "distance": self.distance
        ]
    }
    
    public func generateURL(baseURL: String) -> String {
        return baseURL + "/api/distance/"
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    //DECODING
    public required init?(coder aDecoder: NSCoder) {
        guard let date: Date = aDecoder.decodeObject(of: NSDate.self, forKey: "date") as Date?,
            let description: String = aDecoder.decodeObject(of: NSString.self, forKey: "description") as String?,
            let distance: Double = aDecoder.decodeObject(of: NSNumber.self, forKey: "distance")?.doubleValue else {
            return nil
        }
        
        self.date = date
        self.data_description = description
        self.distance = distance
        
        super.init()
    }
    
    public required init?(json: JSON) {
        
        guard let date: Date = "date" <~~ json,
            let description: String = "description" <~~ json,
            let distance: Double = "distance" <~~ json else {
            return nil
        }
        
        self.date = date
        self.data_description = description
        self.distance = distance
        
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
        closure("description", self.data_description as NSString)
        closure("distance", self.distance as NSNumber)
    }
    
    public let date: Date
    let data_description: String
    let distance: Double
    
    public init(date: Date,
                data_description: String,
                distance: Double) {
        
        
        self.date = date
        self.data_description = data_description
        self.distance = distance
        
        super.init()
        
    }
    

}
