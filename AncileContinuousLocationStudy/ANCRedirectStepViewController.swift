//
//  ANCRedirectStepViewController.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 7/13/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

import UIKit
import ResearchKit
import sdlrkx

open class ANCRedirectStepViewController: ORKStepViewController {
    
    weak open var redirectDelegate: ANCRedirectStepDelegate?
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var button: CTFBorderedButton!
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    open func configure(with step: ORKStep?, result: ORKResult?) {
        self.step = step
        self.restorationIdentifier = step!.identifier
        guard let redirectStep = step as? ANCRedirectStep else {
            return
        }
        
        self.redirectDelegate = redirectStep.delegate
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        fatalError("init(coder:) has not been implemented")
    }
    
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.titleLabel.text = self.step?.title
        self.textLabel.text = self.step?.text
        self.button.setTitle((self.step as? ANCRedirectStep)?.buttonText, for: .normal)
        
        self.redirectDelegate?.redirectViewControllerDidLoad(viewController: self)
    }
    
    @IBAction func buttonTapped(_ sender: Any) {
        self.redirectDelegate?.beginRedirect(completion: { (error) in
            debugPrint(error)
            if error == nil {
                DispatchQueue.main.async {
                    super.goForward()
                }
            }
            else {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Log in failed", message: "Username / Password are not valid", preferredStyle: UIAlertControllerStyle.alert)
                    
                    // Replace UIAlertActionStyle.Default by UIAlertActionStyle.default
                    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                        (result : UIAlertAction) -> Void in
                        print("OK")
                    }
                    
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                }
                
            }
        })
    }
    

}
