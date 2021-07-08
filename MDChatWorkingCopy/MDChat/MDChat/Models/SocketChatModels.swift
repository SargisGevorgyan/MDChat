//
//  ChatModels.swift
//  Jade
//
//  Created by Davit Ghushchyan on 7/6/21.
//

import Foundation
import SocketIO

struct SocketEvents {
    enum  User: String {
        case addUser = "add_user"
        case userJoined = "user_joined"
        case userLeft = "user_left"
    }
    
    enum Message: String {
        case typing = "typing"
        case stopTyping = "stop_typing"
        case newMessage = "new_message"
        case deleteMessage = "delete_message"
    }
}

enum MessageContentType: Int, Codable {
    case message = 0
    case photo
    case video
    case document
}

struct MessageObject: Codable, SocketData {
    let uuid: String
    let contentType: MessageContentType
    let date: Date
    let text: String
    let senderID: String
    
    func socketRepresentation() throws -> SocketData {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(self)
            if let string = String(data: data, encoding: .utf8) {
                return string
            } else {
                throw NSError()
            }
        } catch {
            throw error
        }
    }
}

struct ChatMember: Codable {
    var id: String
    var name: String
    var avatarURL: String
    var lastOnline: Date
}

protocol ChatRoomDelegate: AnyObject {
    func didUpdate(messageObject: MessageObject, at index: Int)
    func didInsert(messageObject: MessageObject, at index: Int)
    func didUpdateMemberList()
}

struct ChatRoom {
    var name: String?
    var isPrivate: Bool = false
    var messages: [MessageObject] = []
    var members: [ChatMember] = []
    var admin: ChatMember?
    var lastUpdateDate: Date = Date()
    var isConnected: Bool = false
    
    weak var delegate: ChatRoomDelegate?
    
    mutating func didRecieved(messageObject: MessageObject) {
        if let messageIndex = messages.firstIndex(where: { messageObject.uuid == $0.uuid }) {
            messages[messageIndex] = messageObject
            delegate?.didUpdate(messageObject: messageObject, at: messageIndex)
        } else {
            messages.append(messageObject)
            delegate?.didInsert(messageObject: messageObject, at: messages.count - 1 )
        }
        lastUpdateDate = Date()
    }
    
    mutating func addMember(_ member: ChatMember) {
        members.append(member)
        delegate?.didUpdateMemberList()
    }
    
    mutating func removeMember(_ memberId: String) {
        members = members.filter { $0.id != memberId}
        delegate?.didUpdateMemberList()
    }
}
