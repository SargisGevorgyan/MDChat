
import UIKit
import TwilioChatClient
import TwilioAccessManager
import SwiftyMDLib

enum ChannelRoomType: String, Codable {
    case seller
    case buyer
    case host
}

class ChatManager: NSObject {
    
    static let shared = ChatManager()
    
    var connectionCompleted:(()->())?
    
    var client:TwilioChatClient?
    var delegate:ChatChannelManager?
    var connected = false
    
    var lastPushToken: Data? {
        didSet {
            updateChatClient()
        }
    }
    
    var lastNotification: [AnyHashable: Any]? {
        didSet {
            updateChatClient()
        }
    }
    
    var twilioToken:String? {
        didSet {
            if !(twilioToken?.isEmpty ?? false) {
                //                self.connectChat {}
            }
        }
    }
    
    var userIdentity:String {
        return ChatSessionManager.getUsername()
    }
    
    var hasIdentity: Bool {
        return ChatSessionManager.isLoggedIn()
    }
    
    private override init() {
        super.init()
        delegate = ChatChannelManager.shared
    }
    
    func updateChatClient() {
        
        if (client != nil) && (client?.synchronizationStatus == TCHClientSynchronizationStatus.completed || client?.synchronizationStatus == TCHClientSynchronizationStatus.channelsListCompleted) {
            if let lastPushToken = lastPushToken {
                client?.register(withNotificationToken: lastPushToken, completion: { (result) in
                    if result.isSuccessful() {
                        
                    } else {
                        // try again?
                    }
                })
            }
            
            
            if let lastNotification = lastNotification {
                client?.handleNotification(lastNotification) { result in
                    if result.isSuccessful() {
                        self.lastNotification = nil
                    } else {
                        // try again?
                    }
                }
            }
        }
    }
    
    func connectChat(username:String, completion:@escaping ()->()) {
        
        connectionCompleted = completion
        
        if (!hasIdentity) {
            loginWithUsername(username: username) { (success, error) in
                if success {
                    self.connectChat(username:username, completion: completion)
                }
            }
            return
        }
        
        if (!connected) {
            connectClientWithCompletion { success, error in
                print("Delegate method will load views when sync is complete")
                if (!success || error != nil) {
                    DispatchQueue.main.async {
                        self.logout()
                        self.connectChat(username:username, completion: completion)
                    }
                }
            }
            return
        }
        
        connectionCompleted?()
    }
    
    func disconnect() {
        
        
    }
    
    func presentViewControllerByName(viewController: String) {
        presentViewController(controller: storyBoardWithName(name: "Main").instantiateViewController(withIdentifier: viewController))
    }
    
    func presentLaunchScreen() {
        presentViewController(controller: storyBoardWithName(name: "LaunchScreen").instantiateInitialViewController()!)
    }
    
    func presentViewController(controller: UIViewController) {
        let window = UIApplication.shared.delegate!.window!!
        window.rootViewController = controller
    }
    
    func storyBoardWithName(name:String) -> UIStoryboard {
        return UIStoryboard(name:name, bundle: Bundle.main)
    }
    
    //MARK: - Open Channel For Users
    func openChatScreen(for vc:UIViewController, cid: String) {
        Loading.showLoadingOnWindow()
        
        ChatChannelManager.shared.channel(for: cid) { (success, channel) in
            self.openChatScreen(success, channel, vc: vc, invitedUserByIdentity: "")
        }
    }
    
    fileprivate func openChatScreen(_ success: Bool, _ channel: TCHChannel?, vc:UIViewController, invitedUserByIdentity: String) {
        Loading.hideLoadingOnWindow()
        
        if channel != nil {
            if let viewController = self.instantiateController(withIdentifier: AppChatViewController.id) as? AppChatViewController {
                vc.navigationController?.pushViewController(viewController)
                viewController.channelMessages.channel = channel
                if !invitedUserByIdentity.isEmpty {
                    channel?.members?.add(byIdentity: invitedUserByIdentity, completion: { (result) in
                    })
                }
            }
        } else {
            DialogsManager.showError(error: "error_something_wrong".localize())
        }
    }
    
    func openChatScreen(vc:UIViewController, firstUser: UserResposeModel?, secondUser: UserResposeModel?, roomType: ChannelRoomType, attributes: String) {
        if AppManager.shared.isGuestUser == true {
            if let navigationController = self.appCurrentController()?.appTabBarController?.navigationController {
                GuestManager.openSignInForGuest(nc: navigationController)
            }
            return
        }
        if let chatUserName = AppManager.shared.currentUser?.chatUserName {
            Loading.showLoadingOnWindow()
            ChatManager.shared.connectChat(username: chatUserName, completion: {
                
                var firstUserId = ""
                var lastUserId = ""
                
                var invitedUserByIdentity = ""
                
                firstUserId = firstUser?.chatUserId ?? ""
                lastUserId = secondUser?.chatUserId ?? ""
                invitedUserByIdentity = secondUser?.chatUserEmail ?? ""
                
                //                let uniqueName = firstUserId + AppCommonParams.channelSeparator1 + lastUserId + AppCommonParams.channelSeparator2 + roomType.rawValue
                let uniqueName = firstUserId + AppCommonParams.channelSeparator1 + lastUserId
                let reveresedUniqueName = lastUserId + AppCommonParams.channelSeparator1 + firstUserId
                
                ChatChannelManager.shared.fetchChannel(uniqueName: reveresedUniqueName) { (success, channel) in
                    var strAttr = attributes
                    if success {
                        if let attr = channel?.attributes() {
                            if attr.isString {
                                strAttr = attr.string!
                            }
                        }
                    }
                    ChatChannelManager.shared.channel(with :strAttr, uniqueName: (success ? reveresedUniqueName : uniqueName)) { (success, channel) in
                        
                        self.openChatScreen(success, channel, vc: vc, invitedUserByIdentity: invitedUserByIdentity)
                    }
                }
            })
        }
    }
    //MARK: - User Image
    func updateUserAvatarUrl(avatarUrl:String?) {
        //avatarUrl
        let attributes = TCHJsonAttributes(dictionary: ["avatarUrl" : avatarUrl ?? ""])
        client?.user?.setAttributes(attributes, completion: { (result) in
            
        })
    }
    // MARK: User and session management
    
    func loginWithUsername(username: String,
                           completion: @escaping (Bool, NSError?) -> Void) {
        ChatSessionManager.loginWithUsername(username: username)
        connectClientWithCompletion(completion: completion)
    }
    
    fileprivate func deInitClient() {
        ChatSessionManager.logout()
        DispatchQueue.global(qos: .userInitiated).async {
            self.client?.shutdown()
            self.client = nil
        }
        ChatChannelManager.shared.channelsList = nil
        ChatChannelManager.shared.channels = nil
        self.twilioToken = nil
        self.connected = false
    }
    
    func logout() {
        
        if let lastPushToken = lastPushToken {
            client?.deregister(withNotificationToken: lastPushToken, completion: { (result) in
                self.deInitClient()
            })
        } else {
            deInitClient()
        }
    }
    
    // MARK: Twilio Client
    func connectClientWithCompletion(completion: @escaping (Bool, NSError?) -> Void) {
        if (client != nil) {
            logout()
        }
        
        requestTokenWithCompletion { succeeded, token in
            if let token = token, succeeded {
                self.initializeClientWithToken(token: token)
                completion(succeeded, nil)
            }
            else {
                let error = self.errorWithDescription(description: "Could not get access token", code:301)
                completion(succeeded, error)
            }
        }
    }
    
    func initializeClientWithToken(token: String) {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            TwilioChatClient.chatClient(withToken: token, properties: nil, delegate: self) { [weak self] result, chatClient in
                guard (result.isSuccessful()) else { return }
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self?.connected = true
                self?.client = chatClient
            }
        }
    }
    
    func requestTokenWithCompletion(completion:@escaping (Bool, String?) -> Void) {
        if AppTarget.current == .tekramChat {
            let token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImN0eSI6InR3aWxpby1mcGE7dj0xIn0.eyJqdGkiOiJTS2ViZmE4ZTIzNDA0YzE3Yjg2MzI5MGNiZTVmZWI0OGE0LTE1OTQ2MzgwNDUiLCJpc3MiOiJTS2ViZmE4ZTIzNDA0YzE3Yjg2MzI5MGNiZTVmZWI0OGE0Iiwic3ViIjoiQUM5NWM5NDllZWFhNGFkZjFlN2QxYWM2MDhhZmJiN2IyNSIsImV4cCI6MTU5NDcyNDQ0NSwiZ3JhbnRzIjp7ImlkZW50aXR5IjoidGVzdDFAbWQuY29tXzIiLCJjaGF0Ijp7InNlcnZpY2Vfc2lkIjoiSVMxZDdjODkyYjgwMzk0MDFmYWRmNzFjZWM5MTRmNDY3MyIsInB1c2hfY3JlZGVudGlhbF9zaWQiOiJDUmE2YWIxYmQ0ZmI1NTU4MzhlZjA3ZTI0MWZmNDBmMDgyIn19fQ.8i_rlLBx3y6GvihHll2nkr_-zxH2OLzRoj-xthm5NiM"
            completion(true, token)
        } else {
            if self.twilioToken?.isEmpty ?? true {
                TwilioAccessTokenRequest.fetchToken(success: { (token) in
                    self.twilioToken = token
                    completion(true, self.twilioToken)
                }) { (error) in
                    print(error)
                }
            } else {
                completion(true, self.twilioToken)
            }
        }
    }
    
    func errorWithDescription(description: String, code: Int) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey : description]
        return NSError(domain: "app", code: code, userInfo: userInfo)
    }
}

// MARK: - TwilioChatClientDelegate
extension ChatManager : TwilioChatClientDelegate {
    func chatClient(_ client: TwilioChatClient, channelAdded channel: TCHChannel) {
        self.delegate?.chatClient(client, channelAdded: channel)
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, updated: TCHChannelUpdate) {
        self.delegate?.chatClient(client, channel: channel, updated: updated)
    }
    
    func chatClient(_ client: TwilioChatClient, channelDeleted channel: TCHChannel) {
        self.delegate?.chatClient(client, channelDeleted: channel)
    }
    
    func chatClient(_ client: TwilioChatClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
        if status == TCHClientSynchronizationStatus.completed {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            ChatChannelManager.shared.channelsList = client.channelsList()
            ChatChannelManager.shared.populateChannels()
            self.updateChatClient()
            self.connectionCompleted?()
            
        }
        self.delegate?.chatClient(client, synchronizationStatusUpdated: status)
    }
    
    //MARK: - Notiifcations
    func chatClient(_ client: TwilioChatClient, notificationUpdatedBadgeCount badgeCount: UInt) {
        
    }
    
    func chatClient(_ client: TwilioChatClient, notificationInvitedToChannelWithSid channelSid: String) {
        
    }
    
    func chatClient(_ client: TwilioChatClient, notificationAddedToChannelWithSid channelSid: String) {
        
    }
    
    func chatClient(_ client: TwilioChatClient, notificationRemovedFromChannelWithSid channelSid: String) {
        
    }
    
    func chatClient(_ client: TwilioChatClient, notificationNewMessageReceivedForChannelSid channelSid: String, messageIndex: UInt) {
        
    }
}

// MARK: - TwilioAccessManagerDelegate
extension ChatManager : TwilioAccessManagerDelegate {
    func accessManagerTokenWillExpire(_ accessManager: TwilioAccessManager) {
        self.twilioToken = nil
        requestTokenWithCompletion { succeeded, token in
            if (succeeded) {
                accessManager.updateToken(token!)
            }
            else {
                print("Error while trying to get new access token")
            }
        }
    }
    
    func accessManager(_ accessManager: TwilioAccessManager!, error: Error!) {
        print("Access manager error: \(error.localizedDescription)")
    }
}

protocol ChatManagerDelegate: class {
    func chatConnected()
}
