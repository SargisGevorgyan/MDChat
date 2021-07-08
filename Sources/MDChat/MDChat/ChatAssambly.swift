//
//  ChatAssambly.swift
//  Jade
//
//  Created by Davit Ghushchyan on 7/8/21.
//

import UIKit
import SwiftyMDLib

public struct ChatConfigurations {
    let roomID: String
}

public final class ChatAssambly {
    
    public static func openChat(navigationController: UINavigationController, with configurations: ChatConfigurations) {
        if let  vc = NSObject().instantiateController(withIdentifier: AppChatViewController.id) as? AppChatViewController  {
            
        }
    }
}
