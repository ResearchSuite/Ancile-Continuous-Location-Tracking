//
//  SplashViewController.swift
//  AncileContinuousLocationStudy
//
//  Created by Christina Tsangouri on 7/31/17.
//  Copyright © 2017 Christina Tsangouri. All rights reserved.
//

import UIKit
import ResearchSuiteAppFramework
import ResearchKit

class SplashViewController: UIViewController {

    @IBOutlet weak var settingsButton: UIBarButtonItem!
    var store: ANCStore!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.store = ANCStore()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func viewDidAppear(_ animated: Bool) {
        let shouldDoDaily = self.store.get(key: "shouldDoDaily") as! Bool
        
        if (shouldDoDaily) {
            
            self.launchDailySurvey()
        }
        
      
    }
    
    func launchDailySurvey() {
        
        guard let task = AppDelegate.appDelegate.activityManager.task(for: "dailySurvey"),
            let activity = AppDelegate.appDelegate.activityManager.activity(for: "dailySurvey") else {
                return
        }
        
        let tvc = RSAFTaskViewController(activityUUID: UUID(), task: task, taskFinishedHandler: { [weak self] (taskViewController, reason, error) in
            
            guard reason == ORKTaskViewControllerFinishReason.completed else {
                self?.dismiss(animated: true, completion: nil)
                return
            }
            
            let taskResult = taskViewController.result
            
            AppDelegate.appDelegate.resultsProcessor.processResult(taskResult: taskResult, resultTransforms: activity.resultTransforms)
            
            self?.dismiss(animated: true, completion: {
                let storyboard = UIStoryboard(name: "Splash",bundle: Bundle.main)
                let vc = storyboard.instantiateInitialViewController()
                AppDelegate.appDelegate.transition(toRootViewController: vc!, animated: true)
            })
            
        })
        
        self.present(tvc, animated: true, completion: nil)
        
    }
    

    
}




