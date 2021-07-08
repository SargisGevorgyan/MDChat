//
//  TCHMessage+Extention.swift
//  ChatExample
//
//  Created by Sargis Gevorgyan on 4/20/20.
//  Copyright © 2020 MessageKit. All rights reserved.
//

import UIKit
import TwilioChatClient

extension TCHMessage {
    var convertedMessage:MockMessage {
        
        if messageType == .media {
            // Set up output stream for media content
            let tempFilename = (NSTemporaryDirectory() as NSString).appendingPathComponent(mediaFilename ?? "file.dat")
            let outputStream = OutputStream(toFileAtPath: tempFilename, append: false)
            
            // Request the start of the download
            if let outputStream = outputStream {
                getMediaWith(outputStream,
                             onStarted: {
                                // Called when download of media begins.
                },
                             onProgress: { (bytes) in
                                // Called as download progresses, with the current byte count.
                },
                             onCompleted: { (mediaSid) in
                                // Called when download is completed, with the new mediaSid if successful.
                                // Full failure details will be provided through the completion block below.
                }) { (result) in
                    if !result.isSuccessful() {
                        print("Download failed: \(String(describing: result.error))")
                    } else {
                        print("Download successful")
                    }
                }
            }
        }
        
        var uniqueID =  UUID().uuidString
        if let sid = self.sid {
             uniqueID = sid
        }
        let user = MockUser(senderId: self.author ?? "000000", displayName: self.member?.displayName ?? "", avatarUrl: self.member?.avatarUrl)
        let date = self.dateCreatedAsDate ?? Date()
        var msgTxt = self.body ?? ""
        if msgTxt.count < 3  {
            msgTxt = "  " + msgTxt + "  "
        }
        var msg = MockMessage(text: msgTxt, user: user, messageId: uniqueID, date: date)
        msg.sentDateTimeStamp = dateCreated
        return msg
    }
    
    var dateHeaderMessage:MockMessage {
        
        if messageType == .media {
            // Set up output stream for media content
            let tempFilename = (NSTemporaryDirectory() as NSString).appendingPathComponent(mediaFilename ?? "file.dat")
            let outputStream = OutputStream(toFileAtPath: tempFilename, append: false)
            
            // Request the start of the download
            if let outputStream = outputStream {
                getMediaWith(outputStream,
                             onStarted: {
                                // Called when download of media begins.
                },
                             onProgress: { (bytes) in
                                // Called as download progresses, with the current byte count.
                },
                             onCompleted: { (mediaSid) in
                                // Called when download is completed, with the new mediaSid if successful.
                                // Full failure details will be provided through the completion block below.
                }) { (result) in
                    if !result.isSuccessful() {
                        print("Download failed: \(String(describing: result.error))")
                    } else {
                        print("Download successful")
                    }
                }
            }
        }
        
        let uniqueID = self.sid ?? UUID().uuidString
        let system = MockUser(senderId: "000000", displayName: "System")
        let date = self.dateCreatedAsDate ?? Date()
        var msg = MockMessage(custom: date.getRelativeDateTodayChecked(), user: system, messageId: uniqueID, date: date)
        msg.sentDateTimeStamp = dateCreated
        return msg
    }
}
