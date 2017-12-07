//
//  LocationEventAction.swift
//  AncileContinuousLocationStudy
//
//  Created by James Kizer on 11/16/17.
//  Copyright © 2017 Christina Tsangouri. All rights reserved.
//

import UIKit

public enum LocationEventAction: String, Codable {
    case enter = "enter"
    case exit = "exit"
    case startedInside = "startedInside"
    case startedOutside = "startedOutside"
    case startedUnknown = "startedUnknown"
}
