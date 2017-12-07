//
//  LocationEvent.swift
//  AncileContinuousLocationStudy
//
//  Created by James Kizer on 11/16/17.
//  Copyright © 2017 Christina Tsangouri. All rights reserved.
//

import UIKit

public struct LocationEvent: Codable {
    
    let uuid: UUID
    let identifier: String
    let action: LocationEventAction
    let timestamp: Date

}
