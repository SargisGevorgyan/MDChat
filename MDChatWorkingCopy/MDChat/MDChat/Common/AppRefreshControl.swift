//
//  AppRefreshControl.swift
//  Tekram
//
//  Created by Sargis Gevorgyan on 8/25/20.
//  Copyright © 2020 MagicDevs. All rights reserved.
//

import UIKit


class AppRefreshControl: UIRefreshControl {

    public static let noInternetNotification = Notification.Name(rawValue:"No internet")
    
    override init() {
        super.init()
        tintColor = ChatConfigs.UIConfigs.mainThemeColor
        self.addTarget(self, action: #selector(handleControlChanges), for: .valueChanged)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
     @objc private func handleControlChanges() {
         
         addObservers()
    }
    
    override func beginRefreshing() {
        super.beginRefreshing()
        
        addObservers()
    }
    
    override func endRefreshing() {
        super.endRefreshing()
        
        removeObservers()
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self,
        selector: #selector(handleNoInetNotif),
        name: AppRefreshControl.noInternetNotification,
        object: nil)
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc fileprivate func handleNoInetNotif() {
        endRefreshing()
    }

}
