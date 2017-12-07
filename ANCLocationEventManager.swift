//
//  ANCLocationEventManager.swift
//  AncileContinuousLocationStudy
//
//  Created by James Kizer on 11/16/17.
//  Copyright © 2017 Christina Tsangouri. All rights reserved.
//

import UIKit

class ANCLocationEventManager: NSObject {
    
    //generate a bunch of sample data points
    //M-F, leave home at 8AM, arrive at work 8:45, leave work at 5:15, arrive home at 6
    //Weekend, lave home at 12, arrive home at 8
    
    //start date, 10 weeks ago
    
    var events: [LocationEvent] = []
    
    public override init() {
        
        super.init()
        self.events = self.generateEvents()
        
    }
    
    func generateEvents() -> [LocationEvent] {
        
        
        
        return []
    }

}
