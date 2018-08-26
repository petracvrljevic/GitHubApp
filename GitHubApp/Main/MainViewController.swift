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
import WebLinking

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var repositories = [Repo]()
    var searchedRepositories = [Repo]()
    
    var sortType: SortType?
    var searchActive = false
    
    var nextURL: String = ""
    var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Main"
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "RepoTableViewCell", bundle: nil), forCellReuseIdentifier: "repoCell")
        
        setRightBarButtons()
        
        setupSearch()
        downloadRepositories()
    }
    
    func setRightBarButtons() {
        
        let logoutBarButton = UIBarButtonItem(image: UIImage(named: "logoutIcon"), style: .plain, target: self, action: #selector(handleLogout))
        let profileBarButton = UIBarButtonItem(image: UIImage(named: "userIcon"), style: .plain, target: self, action: #selector(handleProfile))
        logoutBarButton.tintColor = UIColor.black
        profileBarButton.tintColor = UIColor.black

        self.navigationItem.rightBarButtonItems = [logoutBarButton, profileBarButton]
    }
    
    @objc func handleProfile() {
        let userDetailsVC = UserDetailsViewController()
        self.navigationController?.pushViewController(userDetailsVC, animated: true)
    }
    
    @objc func handleLogout() {
        UserDefaults.standard.set(false, forKey: "logged")
        UserDefaults.standard.removeObject(forKey: "username")
        Helper.keychain.delete("password")
        UserDefaults.standard.synchronize()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.setRootViewController()
    }

    func downloadRepositories() {
        
        guard let headers = Helper.getBasicAuth() else { return }
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        Alamofire.request(Helper.allRepositoriesURL, headers: headers).responseArray { (response: DataResponse<[Repo]>) in
            
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if let statusCode = response.response?.statusCode, statusCode == 200 {
                if let reposArray = response.result.value {
                    self.repositories = reposArray

                    self.getDetails(in: self.repositories)
                    
                    if let nextLink = response.response?.findLink(relation: "next") {
                        self.nextURL = nextLink.uri
                    }
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
                    
                    if let statusCode = response.response?.statusCode, statusCode == 200 {
                        if let repoDetails = response.result.value {
                            repo.language = repoDetails.language
                            repo.forks = repoDetails.forks
                            repo.openIssues = repoDetails.openIssues
                            repo.watchers = repoDetails.watchers
                            repo.created = repoDetails.created
                            repo.updated = repoDetails.updated
                        }
                        self.tableView.reloadData()
                    }
                })
            }
            if let user = repo.owner, let userURLString = user.url, let userURL = URL(string: userURLString) {
                
                Alamofire.request(userURL, headers: headers).responseObject(completionHandler: { (response: DataResponse<User>) in
                    
                    if let statusCode = response.response?.statusCode, statusCode == 200 {
                        if let userDetails = response.result.value {
                            user.blog = userDetails.blog
                            user.followers = userDetails.followers
                            user.fullName = userDetails.fullName
                            user.location = userDetails.location
                            user.repos = userDetails.repos
                        }
                        self.tableView.reloadData()
                    }
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
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let totalRecords = searchActive ? searchedRepositories.count : repositories.count
        if (indexPath.row + 1 == totalRecords && isLoading == false) {
            isLoading = true
            if searchActive {
                getMoreRepositories(keyPath: "items")
            }
            else {
                getMoreRepositories(keyPath: "")
            }
        }
    }
    
    func getMoreRepositories(keyPath: String) {
        guard let headers = Helper.getBasicAuth() else { return }
        guard let url = URL(string: nextURL) else { return }
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
    
        Alamofire.request(url, method: .get, headers: headers).responseArray(keyPath: keyPath) { (response: DataResponse<[Repo]>) in
            
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if let statusCode = response.response?.statusCode, statusCode == 200 {
                if let reposArray = response.result.value {
                    if self.searchActive {
                        self.searchedRepositories.append(contentsOf: reposArray)
                        self.getDetails(in: self.searchedRepositories)
                    }
                    else {
                        self.repositories.append(contentsOf: reposArray)
                        self.getDetails(in: self.repositories)
                    }
                    
                    self.tableView.reloadData()
                    self.isLoading = false
                }
                if let nextLink = response.response?.findLink(relation: "next") {
                    self.nextURL = nextLink.uri
                }
            }
        }
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
            
            if let statusCode = response.response?.statusCode, statusCode == 200 {
                if let reposArray = response.result.value {
                    self.searchedRepositories = reposArray
                    
                    if !self.searchedRepositories.isEmpty {
                        if let nextLink = response.response?.findLink(relation: "next") {
                            self.nextURL = nextLink.uri
                        }
                        
                        self.getDetails(in: self.searchedRepositories)
                        
                        self.tableView.reloadData()
                        self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                    }
                    else {
                        let alertVC = UIAlertController(title: "Error", message: "Not found", preferredStyle: .alert)
                        alertVC.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        self.present(alertVC, animated: true, completion: nil)
                    }
                }
            }
            else {
                guard let error = response.error?.localizedDescription else { return }
                let alertVC = UIAlertController(title: "Error", message: "Error: " + error, preferredStyle: .alert)
                alertVC.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alertVC, animated: true, completion: nil)
            }
        }
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchActive = true
        tableView.reloadData()
        if self.navigationItem.leftBarButtonItem == nil {
            addDropDownMenu()
        }
        return true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else { return }
        searchBar.endEditing(true)
        searchRepositories(q: text)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        turnOffSearching()
        if !repositories.isEmpty {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            self.searchedRepositories.removeAll()
            tableView.reloadData()
        }
    }
    
    func turnOffSearching() {
        searchActive = false
        searchBar.endEditing(true)
        searchBar.text = ""
        tableView.reloadData()
        addDropDownMenu()
        DispatchQueue.main.async {
            self.searchBar.resignFirstResponder()
        }
    }
}
