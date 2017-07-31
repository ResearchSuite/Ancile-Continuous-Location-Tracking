//
//  ANCOpenURLDelegate.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 7/17/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

import UIKit

public protocol ANCOpenURLDelegate: class {
    
    func handleURL(url: URL) -> Bool

}
