//
//  LoginViewController.swift
//  GitHubApp
//
//  Created by Petra Cvrljevic on 25/08/2018.
//  Copyright © 2018 Petra Cvrljevic. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import KeychainSwift
import MBProgressHUD

class LoginViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    let clientId = "2e3f716396d03894aad3"
    let clientSecret = "f3358bbd82b6999da62189a92b1210adf97511ed"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func login(_ sender: UIButton) {
        
        let params = ["scope": "public_repo,read: user", "note": "dev", "cliend_id": clientId, "client_secret":clientSecret]
        
        let loginURL = URL(string: "https://api.github.com/authorizations")!
        
        if let username = usernameTextField.text, let password = passwordTextField.text {
            UserDefaults.standard.set(username, forKey: "username")
            UserDefaults.standard.synchronize()
            Helper.keychain.set(password, forKey: "password")
        }
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        Alamofire.request(loginURL, method: .get, parameters: params, headers: Helper.getBasicAuth()).responseJSON { (response) in
            
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if let statusCode = response.response?.statusCode, statusCode == 200 {
                UserDefaults.standard.set(true, forKey: "logged")
                UserDefaults.standard.synchronize()
                let mainVC = MainViewController()
                self.present(UINavigationController(rootViewController: mainVC), animated: true, completion: nil)
            }
            else {
                let alertVC = UIAlertController(title: "Error", message: "Problem with logging in. Check username and password.", preferredStyle: .alert)
                alertVC.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alertVC, animated: true, completion: nil)
            }
        }
    }

}
