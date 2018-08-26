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
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func urlTapped(_ sender: UIButton) {
        if let urlString = user?.htmlURL, let url = URL(string: urlString) {
            let activities = Freedom.browsers([.chrome, .firefox, .safari])
            let vc = UIActivityViewController(activityItems: [url], applicationActivities: activities)
            present(vc, animated: true, completion: nil)
        }
    }

}
