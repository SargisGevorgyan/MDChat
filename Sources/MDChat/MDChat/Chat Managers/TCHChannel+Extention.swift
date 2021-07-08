//
//  TCHChannel+Extention.swift
//  Vayn_Chat
//
//  Created by Sargis Gevorgyan on 4/21/20.
//  Copyright © 2020 MagicDevs. All rights reserved.
//

import UIKit
import TwilioChatClient

extension TCHChannel {
    
    func loadUsers() {
        
//        members?.members(completion: { (result, paginator) in
//            if paginator != nil {
//                self.loadMembers(paginator: paginator!)
//            }
//        })
    }
    
    func loadMembers(paginator: TCHMemberPaginator) {
        if paginator.hasNextPage() {
            paginator.requestNextPage { (result, paginator) in
                if paginator != nil {
                    self.loadMembers(paginator: paginator!)
                }
            }
        }
        
        paginator.items().forEach({
            ChatManager.shared.client?.users()?.subscribedUser(withIdentity: $0.identity!, completion: { (result, user) in
                if user != nil {
                    
                }
            })
            
        })
    }
    
    func remove(completion: @escaping ()->()) {
        destroy { result in
            if (result.isSuccessful()) {
                completion()
            }
            else {
                print("You can not delete this channel")
                self.leave(completion: { (result) in
                    if (result.isSuccessful()) {
                        completion()
                    }
                    else {
                        print("You can not leave this channel")
                        self.declineInvitation(completion: { (result) in
                            if (result.isSuccessful()) {
                                completion()
                            }
                            else {
                                print("You can not decline Invitation this channel")
                                completion()
                            }
                        })
                    }
                })
                
            }
        }
    }
}
