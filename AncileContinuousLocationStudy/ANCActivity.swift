//
//  ANCActivity.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 7/10/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

import UIKit
import Gloss
import ResearchSuiteResultsProcessor

class ANCActivity: Gloss.Decodable {

    
    let identifier: String
    let type: String
    let element: JSON
    let resultTransforms: [RSRPResultTransform]
    required public init?(json: JSON) {
        
        guard let type: String = "type" <~~ json,
            let identifier: String = "identifier" <~~ json,
            let element: JSON = "element" <~~ json else {
                return nil
        }
        self.identifier = identifier
        self.type = type
        self.element = element
        self.resultTransforms = {
            guard let resultTransforms: [JSON] = "resultTransforms" <~~ json else {
                return []
            }
            
            return resultTransforms.flatMap({ (transform) -> RSRPResultTransform? in
                return RSRPResultTransform(json: transform)
            })
        }()
    }
    
}
