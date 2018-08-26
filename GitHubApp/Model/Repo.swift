//
//  Repo.swift
//  GitHubApp
//
//  Created by Petra Cvrljevic on 25/08/2018.
//  Copyright © 2018 Petra Cvrljevic. All rights reserved.
//

import UIKit
import ObjectMapper

class Repo: Mappable {
    var id: Int?
    var name: String?
    var fullName: String?
    var owner: User?
    var url: String?
    var htmlURL: String?
    var language: String?
    var forks: Int?
    var openIssues: Int?
    var watchers: Int?
    var created: String?
    var updated: String?
    
    required init?(map: Map) {
    
    }
    
    func mapping(map: Map) {
        id <- map["id"]
        name <- map["name"]
        fullName <- map["full_name"]
        owner <- map["owner"]
        url <- map["url"]
        htmlURL <- map["html_url"]
        language <- map["language"]
        forks <- map["forks"]
        openIssues <- map["open_issues"]
        watchers <- map["watchers"]
        created <- map["created_at"]
        updated <- map["updated_at"]
    }
}
