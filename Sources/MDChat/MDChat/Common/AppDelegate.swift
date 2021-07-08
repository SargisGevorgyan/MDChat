//
//  AppDelegate.swift
//  Vayn_Chat
//
//  Created by Sargis Gevorgyan on 4/20/20.
//  Copyright © 2020 MagicDevs. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import IQKeyboardManagerSwift
import SwiftyMDLib

@UIApplicationMain


class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        configureIQkeyboard()
        
//        ChatManager.shared.connectChat {}
        
        return true
    }
    
    func configureIQkeyboard() {
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 80.0
        IQKeyboardManager.shared.previousNextDisplayMode = .alwaysHide
        IQKeyboardManager.shared.enableAutoToolbar = false
        //        IQKeyboardManager.shared.toolbarDoneBarButtonItemText = "title_confirm".localize()
    }
    
}

