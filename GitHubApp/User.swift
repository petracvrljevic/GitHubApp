//
//  User.swift
//  GitHubApp
//
//  Created by Petra Cvrljevic on 24/08/2018.
//  Copyright © 2018 Petra Cvrljevic. All rights reserved.
//

import UIKit
import ObjectMapper

class User: Mappable  {
    var id: Int?
    var username: String?
    var avatarURL: String?
    var fullName: String?
    var blog: String?
    var location: String?
    var repos: Int?
    var followers: Int?
    var url: String?
    var htmlURL: String?
    
    required init(map: Map) {
        
    }
    
    func mapping(map: Map) {
        id <- map["id"]
        username <- map["login"]
        avatarURL <- map["avatar_url"]
        fullName <- map["name"]
        blog <- map["blog"]
        location <- map["location"]
        repos <- map["public_repos"]
        followers <- map["followers"]
        url <- map["url"]
        htmlURL <- map["html_url"]
    }
}
