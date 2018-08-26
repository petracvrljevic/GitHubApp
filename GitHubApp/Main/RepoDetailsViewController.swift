//
//  RepoDetailsViewController.swift
//  GitHubApp
//
//  Created by Petra Cvrljevic on 25/08/2018.
//  Copyright © 2018 Petra Cvrljevic. All rights reserved.
//

import UIKit
import Freedom

class RepoDetailsViewController: UIViewController {
    
    @IBOutlet weak var repoNameLabel: UILabel!
    @IBOutlet weak var languageLabel: UILabel!
    @IBOutlet weak var forksLabel: UILabel!
    @IBOutlet weak var issuesLabel: UILabel!
    @IBOutlet weak var watchersLabel: UILabel!
    @IBOutlet weak var createdLabel: UILabel!
    @IBOutlet weak var updatedLabel: UILabel!
    @IBOutlet weak var urlButton: UIButton!
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var publicReposLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    var repo: Repo?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let repo = repo {
            
            if let name = repo.name {
                repoNameLabel.text = name
            }
            
            if let language = repo.language {
                languageLabel.text = language
            }
            
            if let forks = repo.forks {
                forksLabel.text = "\(forks)"
            }
            
            if let issues = repo.openIssues {
                issuesLabel.text = "\(issues)"
            }
            
            if let watchers = repo.watchers {
                watchersLabel.text = "\(watchers)"
            }
            
            let dateFormatterGet = DateFormatter()
            dateFormatterGet.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
            
            if let created = repo.created {
                createdLabel.text = dateFormatter.string(from: dateFormatterGet.date(from: created)!)
            }
            
            if let updated = repo.updated {
                updatedLabel.text = dateFormatter.string(from: dateFormatterGet.date(from: updated)!)
            }
            
            if let user = repo.owner {
                if let username = user.username { usernameLabel.text = username }
                if let fullName = user.fullName { fullNameLabel.text = fullName }
                if let repos = user.repos { publicReposLabel.text = "\(repos)" }
                if let location = user.location { locationLabel.text = location }
            }
            
            if let htmlURL = repo.htmlURL {
                urlButton.setTitle(htmlURL, for: .normal)
            }
        }
    }

    @IBAction func urlTapped(_ sender: UIButton) {
        guard let htmlURL = repo?.htmlURL else { return }
        guard let url = URL(string: htmlURL) else { return }
        
        let activities = Freedom.browsers([.chrome, .firefox, .safari])
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: activities)
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func userDetailsTapped(_ sender: UIButton) {
        if let user = repo?.owner {
            let userDetailsVC = UserDetailsViewController()
            userDetailsVC.user = user
            self.navigationController?.pushViewController(userDetailsVC, animated: true)
        }
    }
    
}
