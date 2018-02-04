//
//  RSFonts.swift
//  ResearchSuiteExtensions
//
//  Created by James Kizer on 1/15/18.
//

import UIKit

open class RSFonts: NSObject {
    
    open class func computeFont(startingTextStyle: UIFontTextStyle, defaultSize: Double, typeAdjustment: Double, weight: UIFontWeight = UIFontWeightRegular) -> UIFont {

        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: startingTextStyle)
        let fontSize: Double = (descriptor.object(forKey: UIFontDescriptorSizeAttribute) as! NSNumber).doubleValue - defaultSize + typeAdjustment
        return UIFont.systemFont(ofSize: CGFloat(fontSize), weight: weight)
        
    }

}
