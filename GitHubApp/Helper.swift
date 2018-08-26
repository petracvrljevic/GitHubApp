//
//  Helper.swift
//  GitHubApp
//
//  Created by Petra Cvrljevic on 24/08/2018.
//  Copyright © 2018 Petra Cvrljevic. All rights reserved.
//

import UIKit
import KeychainSwift

class Helper: NSObject {

    static let basicURL = "https://api.github.com"
    static let header = ["Accept":"application/vnd.github.v3+json"]
    
    static let allRepositoriesURL = URL(string: basicURL + "/repositories")!
    
    static let searchURL = URL(string: basicURL + "/search/repositories")!
    
    static let keychain = KeychainSwift()
    
    static func getBase64Credentials() -> String? {
        var authorization = ""
        if let username = UserDefaults.standard.string(forKey: "username"), let password = keychain.get("password") {
            let credentialData = String(format: "%@:%@", username, password).data(using: String.Encoding.utf8)!
            let base64Credentials = credentialData.base64EncodedString()
            authorization = "Basic \(base64Credentials)"
            return authorization
        }
        return nil
    }
    
    static func getBasicAuth() -> [String:String]? {
        if let base64Credentials = getBase64Credentials() {
            let headers = ["Authorization": base64Credentials,
                           "Accept":"application/vnd.github.v3+json"]
            return headers
            
        }
        return nil
    }
    
    static func loggedUserURL() -> URL? {
        if let username = UserDefaults.standard.string(forKey: "username") {
            return URL(string: basicURL + "/users/\(username)")
        }
        return nil
    }

}
