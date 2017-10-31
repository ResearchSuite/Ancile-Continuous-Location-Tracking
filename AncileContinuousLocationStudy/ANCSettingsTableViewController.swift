//
//  ANCSettingsTableViewController.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 10/16/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

import UIKit
import ResearchSuiteAppFramework
import ResearchKit

class ANCSettingsTableViewController: UITableViewController {

    @IBOutlet weak var surveyTimeCell: UITableViewCell!
    @IBOutlet weak var participantSinceCell: UITableViewCell!
    @IBOutlet weak var versionCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        ANCNotificationManager.printPendingNotifications()
        
        self.updateUI()
    }

    @IBAction func dismissTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func signOutTapped(_ sender: Any) {
        
        let title = "Sign Out?"
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        let logoutAction = UIAlertAction(title: "Sign Out", style: .destructive, handler: { _ in
            AppDelegate.appDelegate.signOut()
        })
        alert.addAction(logoutAction)
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func versionString() -> String {
        
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
            let config = Bundle.main.infoDictionary?["Config"] as? String
            else {
                return "Unknown Version"
        }
        
        return "\(config) Version \(version) (Build \(build))"
    }
    
    private func getActivityIDForReuseIdentifier(_ reuseIdentifier: String) -> String? {
        
        switch reuseIdentifier {
        case "set_survey_time":
            return "notificationTime"
            
        case "launch_survey":
            return "dailySurvey"
            
        case "update_home":
            return "homeLocation"
            
        case "update_work":
            return "workLocation"
            
        default:
            return nil
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.isSelected = false
            
            //add logout here
            guard let reuseIdentifier = cell.reuseIdentifier,
                let activityID = self.getActivityIDForReuseIdentifier(reuseIdentifier) else {
                return
            }
            
            print(reuseIdentifier)
            
            guard let task = AppDelegate.appDelegate.activityManager.task(for: activityID) else {
                return
            }
            
            let tvc = RSAFTaskViewController(activityUUID: UUID(), task: task, taskFinishedHandler: { [weak self] (taskViewController, reason, error) in
                
                guard reason == ORKTaskViewControllerFinishReason.completed,
                    let vc = self else {
                        self?.dismiss(animated: true, completion: nil)
                        return
                }
                
                let taskResult = taskViewController.result
                //view controller, taskResult, handle activity completion
                ANCActivityManager.handleActivityResult(viewController: vc, taskResult: taskResult, completion: { success in
                    self?.presentedViewController?.dismiss(animated: true, completion: nil)
                })
                
            })
            
            self.present(tvc, animated: true, completion: {
                if reuseIdentifier == "launch_survey" {
                    AppDelegate.appDelegate.store.lastSurveyLaunchTime = Date()
                }
            })
        }
    }
    
    func updateUI() {
        self.versionCell.textLabel?.text = self.versionString()
        
        if let date = AppDelegate.appDelegate.store.participantSince {
            let formatter = DateFormatter()
            formatter.dateStyle = DateFormatter.Style.medium
            let dateString = formatter.string(from: date)
            self.participantSinceCell.detailTextLabel?.text = dateString
        }
        else {
            self.participantSinceCell.detailTextLabel?.text = ""
        }
        
        if let components = AppDelegate.appDelegate.store.notificationTime,
            let hour = components.hour,
            let minute = components.minute {
            
            let timeString = String(format: "%d:%.2d %@", (hour % 12 == 0) ? 12 : hour % 12, minute, (hour / 12 == 0) ? "AM" : "PM")
            print(timeString)
            self.surveyTimeCell.detailTextLabel?.text = timeString
        }
        else {
            self.surveyTimeCell.detailTextLabel?.text = ""
        }
    }
    
}
