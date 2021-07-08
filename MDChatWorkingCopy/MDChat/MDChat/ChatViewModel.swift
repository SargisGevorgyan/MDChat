//
//  ChatViewModel.swift
//  Jade
//
//  Created by Davit Ghushchyan on 7/6/21.
//

import Foundation
import SocketIO

protocol ChatRoomViewModelProtocol: AnyObject {
    func send(_ message: MessageObject)
    func join()
    func leave()
    func viewModelFor(index: Int) -> MessageObject
    func numberOfMessages() -> Int
    func reload()
}

protocol ChatViewProtocol {
    func onConnectionLost()
    func onReconnect()
    
    func onStartTyping()
    func onEndTyping()
    
    func onUpdateMemberList()
    
    func insert(message: MessageObject, at index: Int)
    func update(message: MessageObject, at index: Int)
}

class ChatRoomViewModel : ChatRoomViewModelProtocol {
    
    private var socketClient: SocketIOClient
    private var socketManager: SocketManager
    private var view: ChatViewProtocol
    private var chatRoom: ChatRoom
    
    init(socketURL: URL,
         token: String,
         view: ChatViewProtocol,
         chatRoom: ChatRoom) {
        self.view = view
        self.chatRoom = chatRoom
        var socketConfigs: SocketIOClientConfiguration = []
        socketConfigs.insert(.log(true))
        socketConfigs.insert(.compress)
        socketConfigs.insert(.secure(true))
        socketConfigs.insert(.connectParams([
            "deviceId": UIDevice.current.identifierForVendor?.uuidString ?? "",
            "authorization": token
        ]))
        
        let manager = SocketManager(socketURL: socketURL, config: socketConfigs)
        socketManager = manager
        socketClient = manager.defaultSocket
        DispatchQueue.main.async {
            self.chatRoom.delegate = self
        }
        connectSocket()
    }
    
    // MARK: - ChatRoomServiceProtocol
    
    func send(_ message: MessageObject) {
        chatRoom.didRecieved(messageObject: message)
        socketClient.emit(SocketEvents.Message.newMessage.rawValue, message)
    }

    
    // TODO: - Grig-n a anelu te menq ?
    func join() {
        
    }
    
    func leave() {
        
    }
    
    func numberOfMessages() -> Int {
        return chatRoom.messages.count
    }
    
    func viewModelFor(index: Int) -> MessageObject {
        let message = chatRoom.messages[index]
        return message
    }
    
    func reload() {
        
    }
    
}

private extension ChatRoomViewModel {
    func connectSocket() {
        socketClient.on(clientEvent: .connect) { [weak self] _, _ in
            guard let self = self else { return }
            
            self.chatRoom.isConnected = true
            self.addUser()
            
        }
        
        socketClient.on(clientEvent: .disconnect) { [weak self] _, _ in
            guard let self = self else { return }
            
            self.chatRoom.isConnected = false
        }
        
        socketClient.on(SocketEvents.User.userJoined.rawValue) { [weak self] (data, ack) in
            guard let self = self else { return }
            // TODO: - Convert to ChatMember Object and append to the room
//            self.chatRoom.addMember(ChatMember)
        }
        
        socketClient.on("login") {[weak self] (data, ack) in
            guard let self = self else { return }
            
            self.startTyping()
        }
        
        socketClient.on(SocketEvents.User.userLeft.rawValue) { [weak self] (data, ack) in
            // TODO: - getMemberID and remove from the room
//            chatRoom.removeMember(String)
        }
        
        socketClient.on(SocketEvents.Message.typing.rawValue) {[weak self] (data, ack) in
            self?.view.onStartTyping()
        }
        
        socketClient.on(SocketEvents.Message.stopTyping.rawValue) { [weak self] (data, ack) in
            self?.view.onEndTyping()
        }
        
        socketClient.on(SocketEvents.Message.newMessage.rawValue) { [weak self] data, ack in
            guard let self = self else { return }
            
            guard let dict = data[0] as? [String: Any] else { return }
            let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted])
            
            do {
                let decoder = JSONDecoder()
                
                let data = try decoder.decode(MessageObject.self, from: jsonData)
                
                self.chatRoom.didRecieved(messageObject: data)
                
                print(data)
            }
            catch {
                print(error)
            }
            
            let strData = data.compactMap({ $0 as? String })
           
            
            print("adding strData: \(strData)")
        }
        
        socketClient.on(clientEvent: .error) { (data, error) in
            
        }
        
        socketClient.connect()
    }
    
    func addUser() {
        socketClient.emit(SocketEvents.User.addUser.rawValue, "Sargis")
    }
    
    func startTyping() {
        socketClient.emit(SocketEvents.Message.typing.rawValue, "Sargis")
    }
}


extension ChatRoomViewModel: ChatRoomDelegate {
    func didUpdateMemberList() {
        view.onUpdateMemberList()
    }
    
    func didUpdate(messageObject: MessageObject, at index: Int) {
        view.update(message: messageObject, at: index)
    }
    
    func didInsert(messageObject: MessageObject, at index: Int) {
        view.insert(message: messageObject, at: index)
    }
}

