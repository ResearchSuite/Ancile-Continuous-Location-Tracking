//
//  Extensions.swift
//  AncileContinuousLocationStudy
//
//  Created by James Kizer on 10/22/17.
//  Copyright © 2017 Christina Tsangouri. All rights reserved.
//

import ResearchKit
import ResearchSuiteResultsProcessor

extension ORKTimeOfDayQuestionResult: RSRPDefaultValueTransformer {
    
    public var defaultValue: AnyObject? {
        
        let calendar = Calendar(identifier: .gregorian)

        guard let hour = self.dateComponentsAnswer?.hour,
            let minute = self.dateComponentsAnswer?.minute,
            let dateComponents = self.dateComponentsAnswer,
            let date = calendar.date(from: dateComponents) else {
            return nil
        }

        debugPrint(dateComponents)
        debugPrint(date)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        let timeString = timeFormatter.string(from: date)
        
        debugPrint(timeString)
        return timeString as NSString
    }
}
