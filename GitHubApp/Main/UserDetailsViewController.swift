//
//  UserDetailsViewController.swift
//  GitHubApp
//
//  Created by Petra Cvrljevic on 25/08/2018.
//  Copyright © 2018 Petra Cvrljevic. All rights reserved.
//

import UIKit
import Kingfisher
import Freedom
import Alamofire
import AlamofireObjectMapper
import MBProgressHUD

class UserDetailsViewController: UIViewController {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var blogButton: UIButton!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var reposLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var urlButton: UIButton!
    
    var user: User?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if user == nil {
            guard let headers = Helper.getBasicAuth() else { return }
            guard let url = Helper.loggedUserURL() else { return }
            
            MBProgressHUD.showAdded(to: self.view, animated: true)
            
            Alamofire.request(url, headers: headers).responseObject { (response: DataResponse<User>) in
                
                MBProgressHUD.hide(for: self.view, animated: true)
                
                if let statusCode = response.response?.statusCode, statusCode == 200 {
                    if let user = response.value {
                        self.user = user
                        self.fillDetails()
                    }
                }
            }
        }
        else {
         fillDetails()
        }
    }
    
    func fillDetails() {
        guard let user = user else { return }
        
        if let avatarURL = user.avatarURL, let url = URL(string: avatarURL) {
            userImageView.kf.setImage(with: url, placeholder: UIImage(named: "user"))
        }
        
        if let fullName = user.fullName {
            fullNameLabel.text = fullName
        }
        
        if let username = user.username {
            usernameLabel.text = username
        }
        
        if let blog = user.blog {
            blogButton.setTitle(blog, for: .normal)
        }
        
        if let location = user.location {
            locationLabel.text = location
        }
        
        if let repos = user.repos {
            reposLabel.text = "\(repos)"
        }
        
        if let followers = user.followers {
            followersLabel.text = "\(followers)"
        }
        
        if let url = user.htmlURL {
            urlButton.setTitle(url, for: .normal)
        }
    }
    
    @IBAction func blogTapped(_ sender: UIButton) {
        if let blogString = user?.blog, let url = URL(string: blogString) {
            openInBrowsers(url: url)
        }
    }
    
    @IBAction func urlTapped(_ sender: UIButton) {
        if let urlString = user?.htmlURL, let url = URL(string: urlString) {
            openInBrowsers(url: url)
        }
    }
    
    func openInBrowsers(url: URL) {
        let activities = Freedom.browsers([.chrome, .firefox, .safari])
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: activities)
        present(vc, animated: true, completion: nil)
    }

}
