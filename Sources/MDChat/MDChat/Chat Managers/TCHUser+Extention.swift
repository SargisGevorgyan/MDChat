//
//  TCHUser+Extention.swift
//  ChatExample
//
//  Created by Sargis Gevorgyan on 4/20/20.
//  Copyright © 2020 MessageKit. All rights reserved.
//

import UIKit
import TwilioChatClient

extension TCHUser {
    var displayName: String? {
        
        if !(friendlyName?.isEmpty ?? false) {
            return friendlyName
        }
        
        return identity
    }
    
    var avatarUrl: String? {
        
        guard let attritesDict = attributes()?.dictionary else {return ""}
        
        guard let avatarPath = attritesDict["avatarUrl"] as? String else {
            return ""
        }
        
        if !avatarPath.isEmpty {
            return avatarPath
        }
        return ""
    }
}
