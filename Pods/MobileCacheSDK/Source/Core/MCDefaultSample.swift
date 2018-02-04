//
//  MCDefaultSample.swift
//  MobileCacheSDK
//
//  Created by James Kizer on 1/25/18.
//

import UIKit
import Gloss

public class MCDefaultSample: NSObject, MCSample {
    
    public let urlPath: String
    public let data: NSDictionary
    public let date: Date

    public init(urlPath: String, data: NSDictionary, date: Date) {
        self.urlPath = urlPath
        self.data = data
        self.date = date
        super.init()
    }
    
    public func generateURL(baseURL: String) -> String {
        return baseURL + self.urlPath
    }

    public static var supportsSecureCoding: Bool {
        return true
    }
    
    //DECODING
    public required init?(coder aDecoder: NSCoder) {
        guard let data = aDecoder.decodeObject(of: NSDictionary.self, forKey: "data") as NSDictionary?,
            let urlPath = aDecoder.decodeObject(of: NSString.self, forKey: "urlPath") as String?,
            let date = aDecoder.decodeObject(of: NSDate.self, forKey: "date") as Date? else {
            return nil
        }
        
        self.data = data
        self.date = date
        self.urlPath = urlPath
        
        super.init()
    }
    
    
    //ENCODING
    private typealias CodingClosure = (String, Any)->()

    public func dataJSON() -> JSON? {
        return self.data as? JSON
    }
    
    public func encode(with aCoder: NSCoder) {
        let closure: CodingClosure = { (key, value) in
            aCoder.encode(value, forKey: key)
        }
        
        self.encode(closure: closure)
    }
    
    public func encode(closure: (String, Any) -> ()) {
        closure("data", self.data as NSDictionary)
        closure("urlPath", self.urlPath as NSString)
        closure("date", self.date as NSDate)
    }

}
