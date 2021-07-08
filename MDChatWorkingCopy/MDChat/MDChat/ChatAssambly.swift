//
//  ChatAssambly.swift
//  Jade
//
//  Created by Davit Ghushchyan on 7/8/21.


//

import UIKit

public struct ChatConfigurations {
    public let roomID: String
    public let shouldShowTyping = true
}

public struct ChatConfigs {
    public static var socketServerURL: URL = URL(string: "https://socket.jade.support")!
    
    public struct UIConfigs {
        public static var avatarPlaceHolder: UIImage = #imageLiteral(resourceName: "bubble_outlined")
        public static var mainThemeColor: UIColor = .blue
        public static var backgroundColor: UIColor = .systemBackground
        public static var inputViewBackgroundColor: UIColor = .systemGray
        public static var inputViewPlaceHolderColor: UIColor = .placeholderText
        public static var inputViewPlaceHodler = "Write your message here"
        public static var inoutViewSendButtonTitle = "Send"
        
        public static var inputViewSendButtonFont: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize + 2)
        
        public static var messageFont: UIFont = .systemFont(ofSize: UIFont.systemFontSize)
    
        
        public static var receivedBubbleLayerColor: UIColor = .darkGray
        
        public static var controllerTitleColor: UIColor = .darkText
        public static var controllerTitleFont: UIFont = .boldSystemFont(ofSize: UIFont.systemFontSize)
        
    }
}

public final class ChatAssambly {

    public static func startSession() {
        
    }
 
    public static func openChat(navigationController: UINavigationController, with configurations: ChatConfigurations) {
        if let vc = UIStoryboard(name: "ChatMain", bundle: .main).instantiateViewController(identifier: "AppChatViewController" ) as? AppChatViewController {
            
        }
    }
}
