//
//  MockMessage+Extention.swift
//  Vain_ios
//
//  Created by Sargis Gevorgyan on 4/21/20.
//  Copyright © 2020 MagicDevs. All rights reserved.
//

import UIKit


extension MockMessage {
    var dateHeaderMessage:MockMessage {
        let uniqueID =  UUID().uuidString
        let system = MockUser(senderId: "000000", displayName: "System")
        let date = sentDate
        let msg = MockMessage(custom: date.getRelativeDateTodayChecked(), user: system, messageId: uniqueID, date: date)
        
        return msg
    }
}
