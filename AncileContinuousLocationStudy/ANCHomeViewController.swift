//
//  ANCHomeViewController.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 7/27/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

import UIKit
import ResearchSuiteAppFramework
import ResearchKit
import ResearchSuiteTaskBuilder
import Gloss

class ANCHomeViewController: UIViewController {
    
    let minLaunchInterval: TimeInterval = 5*60.0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
//        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .done, target: self, action: #selector(signOut))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.shouldLaunchTask() {
            self.launchTask()
        }
    }
    
    func shouldLaunchTask() -> Bool {
        
        if let lastLaunchTime = AppDelegate.appDelegate.store.lastSurveyLaunchTime {
            debugPrint("time interval \(lastLaunchTime.timeIntervalSinceNow)")
            
            //note that timeIntervalSinceNow returns negative for dates in the past
            return -(lastLaunchTime.timeIntervalSinceNow) > minLaunchInterval
        }
        else {
            return true
        }
        
    }
    
    func launchTask() {
        
        debugPrint("launching task at \(Date())")
        
        guard let task = AppDelegate.appDelegate.activityManager.task(for: "dailySurvey") else {
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
                self?.dismiss(animated: true, completion: nil)
            })
            
        })
        
        self.present(tvc, animated: true, completion: {
            AppDelegate.appDelegate.store.lastSurveyLaunchTime = Date()
        })

    }

}
