//
//  TCHMember_Extention.swift
//  ChatExample
//
//  Created by Sargis Gevorgyan on 4/20/20.
//  Copyright © 2020 MessageKit. All rights reserved.
//

import UIKit
import TwilioChatClient

extension TCHMember {
    var displayName: String? {
        
        
        if identity != nil {
            
            let user = ChatManager.shared.client?.users()?.subscribedUsers().first(where: {
                $0.identity == identity
            })
            
            if user != nil {
                return user?.displayName ?? ""
            }
        }
        
        return identity
    }
    
    var avatarUrl: String? {
        
        if identity != nil {
            if identity == ChatManager.shared.client?.user?.identity {
                return ChatManager.shared.client?.user?.avatarUrl
            }
            
            let user = ChatManager.shared.client?.users()?.subscribedUsers().first(where: {
                $0.identity == identity
            })
            
            if user != nil {
                return user?.avatarUrl!
            }
            
        }
        return ""
    }
}
