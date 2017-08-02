//
//  ANCNotificationManager.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 7/27/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

import UIKit
import UserNotifications

open class ANCNotificationManager: NSObject {
    
    static let kWeeklyNotificationIdentifer: String = "WeeklyNotification"
    
    static let kWeeklyNotificationTitle: String = "Hey 👋"
    static let kWeeklyNotificationBody: String = "It's time to take your weekly survey!"

    static private func getNextDateFromComponents(components: DateComponents) -> Date? {
        return Calendar(identifier: .gregorian).nextDate(after: Date(), matching: components, matchingPolicy: .nextTime)
    }
    
    static public func setNotification(identifier: String, components: DateComponents) {
        
        if #available(iOS 10, *) {
            
            let center = UNUserNotificationCenter.current()
            
            // Enable or disable features based on authorization
            let content = UNMutableNotificationContent()
            content.title = kWeeklyNotificationTitle
            content.body = kWeeklyNotificationBody
            content.sound = UNNotificationSound.default()
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            center.add(request) { (error : Error?) in
                if let theError = error {
                    debugPrint(theError.localizedDescription)
                }
            }
        }
        else {
            
            guard let fireDate = self.getNextDateFromComponents(components: components) else {
                return
            }
            
            let settings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            
            let notification = UILocalNotification()
            notification.userInfo = ["identifier": identifier]
            notification.fireDate = fireDate
            //            notification.repeatInterval = NSCalendar.Unit.weekOfYear
            notification.repeatInterval = NSCalendar.Unit.day
            notification.alertBody = "\(kWeeklyNotificationTitle), \(kWeeklyNotificationBody)"
            UIApplication.shared.scheduleLocalNotification(notification)
            
        }
        
    }
    
    static public func setNotifications() {
        
        //always clear notification before setting
        cancelNotifications()
        
        let setNotificationsClosure = {
            
            let now = Date()
            var components = DateComponents()
            ///matches next monday morning at 9am
            //        components.weekday = 2
            components.hour = 9
            
            setNotification(identifier: kWeeklyNotificationIdentifer, components: components)

        }

        if #available(iOS 10, *) {
            
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
                setNotificationsClosure()
            }
        }
        else {
            setNotificationsClosure()
        }
        
    }
    
    static public func cancelNotification(identifier: String) {
        
        if #available(iOS 10, *) {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        }
        else {
            if let scheduledNotifications = UIApplication.shared.scheduledLocalNotifications {
                let notificationsToCancel = scheduledNotifications.filter({ (notification) -> Bool in
                    guard let userInfo = notification.userInfo as? [String: AnyObject],
                        let userInfoIdentifier = userInfo["identifier"] as? String,
                        userInfoIdentifier == identifier else {
                            return false
                    }
                    return true
                })
                notificationsToCancel.forEach({ (notification) in
                    UIApplication.shared.cancelLocalNotification(notification)
                })
            }
        }
        
    }

    static public func cancelNotifications() {
        
        if #available(iOS 10, *) {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
        else {
            if let scheduledNotifications = UIApplication.shared.scheduledLocalNotifications {
                scheduledNotifications.forEach({ (notification) in
                    UIApplication.shared.cancelLocalNotification(notification)
                })
            }
        }
        
    }
    
    static public func printPendingNotifications() {
        if #available(iOS 10, *) {
            UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (notificationRequests) in
                notificationRequests.forEach { debugPrint($0) }
            })
        }
        else {
            if let scheduledNotifications = UIApplication.shared.scheduledLocalNotifications {
                scheduledNotifications.forEach { debugPrint($0) }
            }
        }
    }

}
