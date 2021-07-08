//
//  ChannelMessagesManager.swift
//  ChatExample
//
//  Created by Sargis Gevorgyan on 4/17/20.
//  Copyright © 2020 MessageKit. All rights reserved.
//

import UIKit
import TwilioChatClient
import TwilioAccessManager
import SwiftyMDLib
import MessageKit

class ChatMessageArchiver {
    struct ChatMessageArchiveObject:Codable {
        static let DBID = "ChatMessageArchiveObject"
        var messages: Data
    }
    static func archive(channelID: String, messages: [MockMessage]) {
        let messagesData = NSKeyedArchiver.archivedData(withRootObject: messages)
        let model = ChatMessageArchiveObject(messages: messagesData)
        CodableManager.shared.saveModelFor(key: ChatMessageArchiveObject.DBID + "__" + channelID, model: model)
    }
    
    static func restore(channelID: String) -> [MockMessage] {
        if let model: ChatMessageArchiveObject = CodableManager.shared.getModelFor(key:  ChatMessageArchiveObject.DBID + "__" + channelID)  {
            let messages = NSKeyedUnarchiver.unarchiveObject(with: model.messages) as? [MockMessage]
            return messages ?? []
        }
        return []
    }

}


class ChannelMessagesManager: NSObject {
    static let DBID = "ChannelMessagesManager"
    
    static let kInitialMessageCountToLoad:UInt = 50
    static let kMoreMessageCountToLoad:UInt = 100
    
    var isOnline = true
    
    var _channel:TCHChannel! // sra id-ov message-ner@ 48 toxin@
    var channel:TCHChannel! {
        get {
            return _channel
        }
        set(channel) {
            _channel = channel
            _channel.delegate = self
            self.joinChannel()
        }
    }
    
    var channelUsers:[TCHUser]? {
        didSet {
            //            self.rebuildMessages()
        }
    }
    
    override init() {
        super.init()
    }
    
    var isLoadingInProgress = false
    var isMoreMessagesLoadingInProgress = false
    
    weak var delegate:ChannelMessagesManagerDelegate?
    
    var messages = [MockMessage]()
    
    var didGoOnline:(()->())?
    
    func goOnline() {
        isOnline = true
        
        if let channelSid = channel.sid {
            TwilioAccessTokenRequest.onlineInChannel(channelSid: channelSid, success: { (result) in
                self.didGoOnline?()
            }) { (error) in
                self.didGoOnline?()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 50) {
            if self.isOnline {
                self.goOnline()
            }
        }
    }
    
    func goOffline() {
        isOnline = false
        
        TwilioAccessTokenRequest.offlineInChannel(success: { (result) in
            
        }) { (error) in
            
        }
        channel.getMessagesCount {[weak self] (result, count) in
            if let self = self {
                if result.isSuccessful() && count == 0 {
                    self.channel.remove {
                        print("Empty Channel Deleted!")
                    }
                }
            }
        }
    }
    
    
    func joinChannel() {
        
        goOnline()
        
        if channel?.status != .joined {
            channel?.join { result in
                print("Channel Joined")
            }
            return
        }
        
        loadMessages()
        loadUsers()
    }
    
    func loadMessages() {
        
        if isLoadingInProgress {
            return
        }
        messages.removeAll()
        isLoadingInProgress = true
        if channel?.synchronizationStatus == .all {
            channel?.messages?.getLastWithCount(ChannelMessagesManager.kInitialMessageCountToLoad) { (result, items) in
                DispatchQueue.main.async {
                    self.isLoadingInProgress = false
                    self.messages.removeAll()
                    self.addMessages(newMessages: Set(items!))
                    self.channel?.messages?.setAllMessagesConsumedWithCompletion({ (result, int) in
                        
                    })
                }
            }
        }
    }
    
    func channelUserAvatarForIdenty(identy:String) ->String {
        if identy == ChatManager.shared.client?.user?.identity {
            return ChatManager.shared.client?.user?.avatarUrl ?? ""
        }
        if let item = channelUsers?.first(where: {$0.identity == identy}) {
            return item.avatarUrl ?? ""
        }
        
        return ""
    }
    
    func loadMoreMessages() {
        
        if isMoreMessagesLoadingInProgress {
            return
        }
        
        isMoreMessagesLoadingInProgress = true
        channel?.messages?.getAfter(UInt(messages.absaluteCount), withCount: ChannelMessagesManager.kMoreMessageCountToLoad, completion: { (result, items) in
            DispatchQueue.main.async {
                self.isMoreMessagesLoadingInProgress = false
                self.instertMessages(newMessages: Set(items!))
            }
        })
    }
    
    func appendAndSortItems(_ newMessages: Set<TCHMessage>) {
        
        newMessages.forEach({
            if !messages.contains(where: $0.convertedMessage){
                messages.append($0.convertedMessage)
            }
        })
        messages = messages.sorted(by: { (a, b) -> Bool in
            (a.sentDate ) < (b.sentDate)
        })
        rebuildMessages()
    }
    
    func addMessages(newMessages: Set<TCHMessage>) {
        
        DispatchQueue.main.async {
            self.appendAndSortItems(newMessages)
            self.delegate?.messagesAdded(items: self.messages)
        }
    }
    
    func insertMessage(newMessage: TCHMessage) {
        
        DispatchQueue.main.async {
            self.appendAndSortItems([newMessage])
            self.delegate?.messageInserted(message: newMessage.convertedMessage)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            self.delegate?.needRebuilData(items: self.messages, scrollBottom: true)
        }
    }
    
    func instertMessages(newMessages: Set<TCHMessage>) {
        DispatchQueue.main.async {
            let sortedItems = self.sortMessagesFor(newMessages)
            if self.messages.first != nil {
                self.messages.removeFirst()
            }
            self.delegate?.needRebuilData(items: self.messages, scrollBottom: false)
            self.appendAndSortItems(newMessages)
            
            self.delegate?.messagesInserted(messages: sortedItems)
        }
    }
    
    func sortMessagesFor(_ items: Set<TCHMessage>) -> [MockMessage] {
        var sortedItems = [MockMessage]()
        items.forEach({
            if !messages.contains(where: $0.convertedMessage){
                sortedItems.append($0.convertedMessage)
            }
        })
        sortedItems = sortedItems.sorted(by: { (a, b) -> Bool in
            (a.sentDate ) < (b.sentDate)
        })
        //        sortedItems = rebuildMessagesforDateHeaders(items: sortedItems)
        return sortedItems
    }
    
    func rebuildMessagesforDateHeaders(items:[MockMessage]) -> [MockMessage] {
        var tmpMsg = [MockMessage]()
        
        for item in messages {
            if case .custom = item.kind {
                continue
            }
            tmpMsg.append(item)
        }
        messages = tmpMsg.sorted(by: { (a, b) -> Bool in
            (a.sentDate ) < (b.sentDate)
        })
        tmpMsg.removeAll()
        
        for (index, item) in messages.enumerated() {
            if index == 0 {
                tmpMsg.append(item.dateHeaderMessage)
            } else {
                if case .custom = item.kind {
                    continue
                }
                let prevMsg = messages[index-1]
                let prevDate = prevMsg.sentDate
                let currentDate = item.sentDate
                
                if !prevDate.isSameDayAsDate(currentDate) {
                    if case .custom = prevMsg.kind {
                        //Prev msg arden Date a
                    } else {
                        tmpMsg.append(item.dateHeaderMessage)
                    }
                }
            }
            tmpMsg.append(item)
        }
        let arr = tmpMsg.sorted(by: { (a, b) -> Bool in
            (a.sentDate ) < (b.sentDate)
        })
        return arr
    }
    
    func rebuildMessages() {
        
        messages = rebuildMessagesforDateHeaders(items: messages)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.delegate?.needRebuilData(items: self.messages, scrollBottom: false)
        }
    }
    
    func sendMessage(inputMessage: String) {
        let messageOptions = TCHMessageOptions().withBody(inputMessage)
        
        channel.messages?.sendMessage(with: messageOptions, completion: { (result, message) in
            
        })
    }
    
    func sendMediaMessage(image: UIImage) {
        let messageOptions = TCHMessageOptions()
        
        guard let data = image.jpegData(compressionQuality: 0.75) else {return}
        let inputStream = InputStream(data: data)
        messageOptions.withMediaStream(inputStream, contentType: "image/jpeg", defaultFilename: "CurrentImg.jpg", onStarted: {
            
        }, onProgress: { (bytes) in
            
        }) { (mediaSid) in
            
        }
        channel.messages?.sendMessage(with: messageOptions, completion: { (result, message) in
            
        })
    }
    
    func sendMessages(_ data: [Any]) {
        for component in data {
            if let str = component as? String {
                sendMessage(inputMessage: str)
            } else if let img = component as? UIImage {
                sendMediaMessage(image: img)
            }
        }
    }
    
    func typing() {
        channel.typing()
    }
    
    func loadUsers() {
//        channel.members?.members(completion: { (result, paginator) in
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
                    self.channelUsers?.append(user!)
                }
            })
            
        })
    }
    
    func currentSender() -> MockUser {
        let user = ChatManager.shared.client?.user
        let sender = MockUser(senderId: user?.identity ?? "", displayName: user?.displayName ?? "", avatarUrl: user?.avatarUrl)
        return sender
    }
}

extension ChannelMessagesManager : TCHChannelDelegate {
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, messageAdded message: TCHMessage) {
        
        if !messages.contains(message.convertedMessage) {
            insertMessage(newMessage: message)
        }
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, memberJoined member: TCHMember) {
        addMessages(newMessages: [StatusMessage(member:member, status:.Joined)])
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, updated: TCHChannelUpdate) {
        
    }
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, memberLeft member: TCHMember) {
        addMessages(newMessages: [StatusMessage(member:member, status:.Left)])
    }
    
    func chatClient(_ client: TwilioChatClient, channelDeleted channel: TCHChannel) {
        DispatchQueue.main.async {
            if channel == self.channel {
                self.delegate?.channelDeleted()
            }
        }
    }
    
    func chatClient(_ client: TwilioChatClient,
                    channel: TCHChannel,
                    synchronizationStatusUpdated status: TCHChannelSynchronizationStatus) {
        if status == .all {
            loadMessages()
        }
    }
    
    func chatClient(_ client: TwilioChatClient, typingStartedOn channel: TCHChannel, member: TCHMember) {
        self.delegate?.clientTypingStartedOn()
    }
    
    func chatClient(_ client: TwilioChatClient, typingEndedOn channel: TCHChannel, member: TCHMember) {
        self.delegate?.clientTypingEndedOn()
    }
}

protocol ChannelMessagesManagerDelegate: class {
    func messagesAdded(items: [MockMessage])
    
    func channelDeleted()
    
    func messageInserted(message: MockMessage)
    
    func messagesInserted(messages: [MockMessage])
    
    func clientTypingStartedOn()
    
    func clientTypingEndedOn()
    
    func needReloadData()
    
    func needRebuilData(items: [MockMessage], scrollBottom:Bool)
}

enum TWCMemberStatus {
    case Joined
    case Left
}

class StatusMessage: TCHMessage {
    var msgMember: TCHMember! = nil
    var status: TWCMemberStatus! = nil
    var _timestamp: String = ""
    override var dateCreated: String {
        get {
            return _timestamp
        }
        set(newTimestamp) {
            _timestamp = newTimestamp
        }
    }
    
    init(member: TCHMember, status: TWCMemberStatus) {
        super.init()
        self.msgMember = member
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0) as TimeZone?
        dateCreated = dateFormatter.string(from: NSDate() as Date)
        self.status = status
    }
}

extension Array where Element == MockMessage {
    var absaluteCount:Int {
        var tmpCount:Int = 0
        
        for item in self {
            if case .custom = item.kind {
                continue
            }
            tmpCount += 1
        }
        
        return tmpCount
    }
    
    func contains(where _item:MockMessage) ->Bool{
        
        for obj in self {
            if obj == _item {
                return true
            }
        }
        
        return false
    }
}
