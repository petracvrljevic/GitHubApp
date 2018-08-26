//
//  MainViewController.swift
//  GitHubApp
//
//  Created by Petra Cvrljevic on 24/08/2018.
//  Copyright © 2018 Petra Cvrljevic. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireObjectMapper
import Kingfisher
import BTNavigationDropdownMenu
import MBProgressHUD

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var repositories = [Repo]()
    var searchedRepositories = [Repo]()
    
    var sortType: SortType?
    var searchActive = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Main"
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "RepoTableViewCell", bundle: nil), forCellReuseIdentifier: "repoCell")
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "logout"), style: .plain, target: self, action: #selector(handleLogout))
        self.navigationItem.rightBarButtonItem?.tintColor = UIColor.black
        
        setupSearch()
        downloadRepositories()
    }
    
    @objc func handleLogout() {
        UserDefaults.standard.set(false, forKey: "logged")
        UserDefaults.standard.removeObject(forKey: "username")
        Helper.keychain.delete("password")
        UserDefaults.standard.synchronize()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.checkIsUserLogged()
    }
    
    
    func downloadRepositories() {
        
        guard let headers = Helper.getBasicAuth() else { return }
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        Alamofire.request(Helper.allRepositoriesURL, headers: headers).responseArray { (response: DataResponse<[Repo]>) in
            
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if response.result.isSuccess {
                if let reposArray = response.result.value {
                    self.repositories = reposArray

                    self.getDetails(in: self.repositories)
                }
            }
            else {
                if let error = response.error {
                    print(error)
                    let alertVC = UIAlertController(title: "Error", message: "Problem with loading data", preferredStyle: .alert)
                    alertVC.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alertVC, animated: true, completion: nil)
                }
            }
        }
    }
    
    func getDetails(in repositories: [Repo]) {
        
        guard let headers = Helper.getBasicAuth() else { return }
        
        for repo in repositories {
            if let repoURLString = repo.url, let repoURL = URL(string: repoURLString) {
                Alamofire.request(repoURL, headers: headers).responseObject(completionHandler: { (response: DataResponse<Repo>) in
                    if let repoDetails = response.result.value {
                        repo.language = repoDetails.language
                        repo.forks = repoDetails.forks
                        repo.openIssues = repoDetails.openIssues
                        repo.watchers = repoDetails.watchers
                        repo.created = repoDetails.created
                        repo.updated = repoDetails.updated
                    }
                    self.tableView.reloadData()
                })
            }
            if let user = repo.owner, let userURLString = user.url, let userURL = URL(string: userURLString) {
                Alamofire.request(userURL, headers: headers).responseObject(completionHandler: { (response: DataResponse<User>) in
                    if let userDetails = response.result.value {
                        user.blog = userDetails.blog
                        user.followers = userDetails.followers
                        user.fullName = userDetails.fullName
                        user.location = userDetails.location
                        user.repos = userDetails.repos
                    }
                    self.tableView.reloadData()
                })
            }
        }
    }
    
    func addDropDownMenu() {
        
        if searchActive {
            
            let dropDownMenuItems = ["No sort", "Stars", "Forks", "Updated"]
            let dropDownMenuView = BTNavigationDropdownMenu(navigationController: self.navigationController, containerView: (self.navigationController?.view)!, title: BTTitle.index(0), items: dropDownMenuItems)
            
            dropDownMenuView.didSelectItemAtIndexHandler = {(indexPath: Int) -> () in
                switch indexPath {
                case 0:
                    self.sortType = nil
                case 1:
                    self.sortType = SortType.stars
                case 2:
                    self.sortType = SortType.forks
                case 3:
                    self.sortType = SortType.updated
                default:
                    print("")
                }
                if self.searchActive, let text = self.searchBar.text {
                    self.searchRepositories(q: text)
                }
            }
            
            self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: dropDownMenuView)
        }
        else {
            self.navigationItem.leftBarButtonItem = nil
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchActive ? searchedRepositories.count : repositories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "repoCell") as! RepoTableViewCell
        let repo = searchActive ? searchedRepositories[indexPath.row] : repositories[indexPath.row]
        if let avatarURL = repo.owner?.avatarURL {
            cell.thumbnailImageView.kf.setImage(with: URL(string: avatarURL), placeholder: UIImage(named: "user"))
        }
        if let username = repo.owner?.username {
            cell.authorLabel.text = username
        }
        
        cell.thumbnailImageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        tapGesture.delegate = self
        cell.thumbnailImageView.tag = indexPath.row
        cell.thumbnailImageView.addGestureRecognizer(tapGesture)
        
        cell.repoLabel.text = repo.name
        cell.forksLabel.text = "\(repo.forks ?? 0)"
        cell.issuesLabel.text = "\(repo.openIssues ?? 0)"
        cell.watchersLabel.text = "\(repo.watchers ?? 0)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let repoDetailsVC = RepoDetailsViewController()
        repoDetailsVC.repo = searchActive ? searchedRepositories[indexPath.row] : repositories[indexPath.row]
        self.navigationController?.pushViewController(repoDetailsVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    @objc func imageTapped(sender: UITapGestureRecognizer) {
        guard let indexPathRow = sender.view?.tag else { return }
        
        if let user = searchActive ? searchedRepositories[indexPathRow].owner : repositories[indexPathRow].owner {
            let userDetailsVC = UserDetailsViewController()
            userDetailsVC.user = user
            self.navigationController?.pushViewController(userDetailsVC, animated: true)
        }
    }

}

extension MainViewController: UISearchBarDelegate {
    
    enum SortType: String {
        case stars = "stars"
        case forks = "forks"
        case updated = "updated"
    }
    
    func setupSearch() {
        searchBar.delegate = self
        searchBar.showsCancelButton = true
    }
    
    func searchRepositories(q: String) {
        
        let params: Parameters
        
        if sortType != nil {
            guard let type = sortType?.rawValue else { return }
            params = ["q": q, "sort": type]
        }
        else {
            params = ["q": q]
        }
        
        guard let headers = Helper.getBasicAuth() else { return }
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        Alamofire.request(Helper.searchURL, method: .get, parameters: params, headers: headers).responseArray(keyPath: "items") { (response: DataResponse<[Repo]>) in
            
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if response.result.isSuccess {
                if let reposArray = response.result.value {
                    self.searchedRepositories = reposArray
                    
                    self.getDetails(in: self.searchedRepositories)
                    
                    self.tableView.reloadData()
                }
            }
            
            if let nextLink = response.response?.allHeaderFields["Link"] as? String {
                print(nextLink)
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else { return }
        searchBar.endEditing(true)
        searchRepositories(q: text)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        turnOffSearching()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            searchActive = false
            tableView.reloadData()
        }
        else {
            searchActive = true
            if self.navigationItem.leftBarButtonItem == nil {
                 addDropDownMenu()
            }
        }
    }
    
    func turnOffSearching() {
        searchActive = false
        searchBar.endEditing(true)
        tableView.reloadData()
        addDropDownMenu()
        DispatchQueue.main.async {
            self.searchBar.resignFirstResponder()
        }
    }
}
