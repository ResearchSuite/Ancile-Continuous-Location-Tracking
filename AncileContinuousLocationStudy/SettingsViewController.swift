//
//  SettingsViewController.swift
//  AncileContinuousLocationStudy
//
//  Created by Christina Tsangouri on 7/31/17.
//  Copyright © 2017 Christina Tsangouri. All rights reserved.
//

import UIKit
import ResearchSuiteAppFramework
import ResearchKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var store: ANCStore!
    @IBOutlet weak var backButton: UIBarButtonItem!
    var items: [String] = ["","Reset your Home Location","","Reset your Work Location","","Sign out"]
    var resultAddressHome : String = ""
    var resultAddressWork: String = ""
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    
    @IBOutlet
    var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.store = ANCStore()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        

        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let deselectedCell = tableView.cellForRow(at: indexPath)!
        deselectedCell.backgroundColor = UIColor.clear
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "cell")!
        
        let homeLocation = self.store.valueInState(forKey: "home_location") as! String
        let workLocation = self.store.valueInState(forKey: "work_location") as! String
        
        NSLog("locations")
        NSLog(homeLocation)
        NSLog(workLocation)
        
        
        if indexPath.row == 0 || indexPath.row == 2 || indexPath.row == 4 {
            cell.textLabel?.textColor = UIColor.black
            cell.backgroundColor = UIColor.init(red:0.95, green:0.95, blue:0.95, alpha:1.0)
            
            if indexPath.row == 0 {
                cell.textLabel?.text = ""
            }
            if indexPath.row == 2 {
                cell.textLabel?.text = homeLocation
            }
            if indexPath.row == 4 {
                cell.textLabel?.text = workLocation
            }
            
        }
        else {
            cell.textLabel?.text = self.items[indexPath.row]
            cell.textLabel?.textColor = UIColor.init(colorLiteralRed: 0, green: 0.7412, blue: 0.9686, alpha: 1.0)
            
        }
        
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.row == 0 || indexPath.row == 2 || indexPath.row == 4 {
            return 40.0
        }
        else {
            return 60.0
        }
        
        
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NSLog(String(describing: indexPath.row))
        tableView.deselectRow(at: indexPath, animated: true)
        
        
        if indexPath.row == 1 {
            self.launchHomeLocationSurvey()
        }
        
        if indexPath.row == 3 {
            self.launchWorkLocationSurvey()
        }
        
        if indexPath.row == 5 {
          //  self.signOut()
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
         self.dismiss(animated: true, completion: nil)
    }
    
    func launchHomeLocationSurvey() {
        guard let task = AppDelegate.appDelegate.activityManager.task(for: "homeLocation"),
            let activity = AppDelegate.appDelegate.activityManager.activity(for: "homeLocation") else {
                return
        }
        
        let tvc = RSAFTaskViewController(activityUUID: UUID(), task: task, taskFinishedHandler: { [weak self] (taskViewController, reason, error) in
            
            guard reason == ORKTaskViewControllerFinishReason.completed else {
                self?.dismiss(animated: true, completion: nil)
                return
            }
            
            let taskResult = taskViewController.result
            AppDelegate.appDelegate.resultsProcessor.processResult(taskResult: taskResult, resultTransforms: activity.resultTransforms)
            
            let resultHome = taskResult.stepResult(forStepIdentifier: "homeLocation")
            let locationAnswerHome = resultHome?.firstResult as? ORKLocationQuestionResult
            let resultCoordHome = locationAnswerHome?.locationAnswer?.coordinate
            let resultRegionHome = locationAnswerHome?.locationAnswer?.region
            var resultDictionaryHome = locationAnswerHome?.locationAnswer?.addressDictionary
            
            self?.resultAddressHome = ""
            var resultAddressPartsHome : [String] = []
            
            if resultDictionaryHome?.index(forKey: "Name") != nil {
                let name = resultDictionaryHome?["Name"] as! String
                resultAddressPartsHome.append(name)
            }
            if resultDictionaryHome?.index(forKey: "City") != nil {
                let city = resultDictionaryHome?["City"] as! String
                resultAddressPartsHome.append(",")
                resultAddressPartsHome.append(" ")
                resultAddressPartsHome.append(city)
            }
            if resultDictionaryHome?.index(forKey: "State") != nil {
                let state = resultDictionaryHome?["State"] as! String
                resultAddressPartsHome.append(",")
                resultAddressPartsHome.append(" ")
                resultAddressPartsHome.append(state)
            }
            if resultDictionaryHome?.index(forKey: "ZIP") != nil {
                let zip = resultDictionaryHome?["ZIP"] as! String
                resultAddressPartsHome.append(",")
                resultAddressPartsHome.append(" ")
                resultAddressPartsHome.append(zip)
                
            }
            
            
            for i in resultAddressPartsHome {
                self?.resultAddressHome = (self?.resultAddressHome)! + i
            }
            
            
            self?.store.setValueInState(value: self!.resultAddressHome as NSSecureCoding , forKey: "home_location")
            
            self?.store.setValueInState(value: resultCoordHome!.latitude as NSSecureCoding, forKey: "home_coordinate_lat")
            self?.store.setValueInState(value: resultCoordHome!.longitude as NSSecureCoding, forKey: "home_coordinate_long")
            
            DispatchQueue.main.async{
                self?.tableView.reloadData()
            }
            
            self?.appDelegate?.updateMonitoredRegions(regionChanged: "home")
            
            self?.dismiss(animated: true, completion: {
            })
            
        })
        
        self.present(tvc, animated: true, completion: nil)
    }
    
    func launchWorkLocationSurvey() {
        guard let task = AppDelegate.appDelegate.activityManager.task(for: "workLocation"),
            let activity = AppDelegate.appDelegate.activityManager.activity(for: "workLocation") else {
                return
        }
        
        let tvc = RSAFTaskViewController(activityUUID: UUID(), task: task, taskFinishedHandler: { [weak self] (taskViewController, reason, error) in
            
            guard reason == ORKTaskViewControllerFinishReason.completed else {
                self?.dismiss(animated: true, completion: nil)
                return
            }
            
            let taskResult = taskViewController.result
            AppDelegate.appDelegate.resultsProcessor.processResult(taskResult: taskResult, resultTransforms: activity.resultTransforms)
            
            let resultWork = taskResult.stepResult(forStepIdentifier: "workLocation")
            let locationAnswerWork = resultWork?.firstResult as? ORKLocationQuestionResult
            let resultCoordWork = locationAnswerWork?.locationAnswer?.coordinate
            let resultRegionWork = locationAnswerWork?.locationAnswer?.region
            var resultDictionaryWork = locationAnswerWork?.locationAnswer?.addressDictionary
            
            self?.resultAddressWork = ""
            var resultAddressPartsWork : [String] = []
            
            if resultDictionaryWork?.index(forKey: "Name") != nil {
                let name = resultDictionaryWork?["Name"] as! String
                resultAddressPartsWork.append(name)
            }
            if resultDictionaryWork?.index(forKey: "City") != nil {
                let city = resultDictionaryWork?["City"] as! String
                resultAddressPartsWork.append(",")
                resultAddressPartsWork.append(" ")
                resultAddressPartsWork.append(city)
            }
            if resultDictionaryWork?.index(forKey: "State") != nil {
                let state = resultDictionaryWork?["State"] as! String
                resultAddressPartsWork.append(",")
                resultAddressPartsWork.append(" ")
                resultAddressPartsWork.append(state)
            }
            if resultDictionaryWork?.index(forKey: "ZIP") != nil {
                let zip = resultDictionaryWork?["ZIP"] as! String
                resultAddressPartsWork.append(",")
                resultAddressPartsWork.append(" ")
                resultAddressPartsWork.append(zip)
                
            }
            
            
            for i in resultAddressPartsWork {
                self?.resultAddressWork = (self?.resultAddressWork)! + i
            }
            
            self?.store.setValueInState(value: self!.resultAddressWork as NSSecureCoding , forKey: "work_location")
            
            self?.store.setValueInState(value: resultCoordWork!.latitude as NSSecureCoding, forKey: "work_coordinate_lat")
            self?.store.setValueInState(value: resultCoordWork!.longitude as NSSecureCoding, forKey: "work_coordinate_long")
            
            DispatchQueue.main.async{
                self?.tableView.reloadData()
            }
            
            self?.appDelegate?.updateMonitoredRegions(regionChanged: "work")

            
            self?.dismiss(animated: true, completion: {
            })
            
        })
        
        self.present(tvc, animated: true, completion: nil)
    }



}
