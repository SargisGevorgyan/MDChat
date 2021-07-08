import UIKit
import TwilioChatClient
import TwilioAccessManager
import SwiftyMDLib

struct ChannelNameModel: Codable {
    var userName: String?
    var userId: Int?
    var ownerName: String?
    var ownerId: Int?
    var id: Int?
    var name: String?
    var type: ChannelRoomType?
    var spaceTypeName:  String?
    var spaceTypeId: Int?
    var address: String?
    var lat, lng: Double?
    var imageUrl: String?
    var ownerImageUrl: String?
    var userImageUrl: String?
    
    var channelName: String {
        var name = ownerName ?? ""
        if ownerId == AppManager.shared.currentUser?.id {
            name = userName ?? ""
        }
        
        return name
    }
    
    var channelUserId: Int? {
        var uId = ownerId ?? 0
        if ownerId == AppManager.shared.currentUser?.id {
            uId = userId ?? 0
        }
        
        return uId
    }
    
    var channelType: ChannelRoomType {
       var roomType = type ?? .seller
        if type == .seller {
            if userId == AppManager.shared.currentUser?.id {
                roomType = .buyer
            }
        }
        return roomType
    }
    
    var imageFullUrl:String {
        var imgUrl = ownerImageUrl
        if ownerId == AppManager.shared.currentUser?.id {
            imgUrl = userImageUrl
        }
        if imgUrl?.isEmpty ?? true {
            return ""
        }
        return EndPoint.current.rawValue + "/" + (imgUrl ?? "")
    }
    
    enum CodingKeys: String, CodingKey {
        case userName
        case ownerName
        case id
        case name
        case type
        case spaceTypeName
        case spaceTypeId
        case address
        case lat, lng
        case imageUrl
        case userId
        case ownerId
        case ownerImageUrl
        case userImageUrl
    }
    
    func getJsonString() -> String {
        var str = ""
        let encoder = JSONEncoder()
        let data = try? encoder.encode(self)
        if let data = data {
            str = String(data: data, encoding: .utf8) ?? ""
        }
        return str
    }

    static func parse(from string: String) -> ChannelNameModel? {
        if let data = string.data(using: .utf8) {
            let decoder = JSONDecoder()
//            if let object = try? decoder.decode(ChannelNameModel.self, from: data) {
//                return object
//            }
            do {
                return try decoder.decode(ChannelNameModel.self, from: data)
            } catch {
                print(error)
                
            }
        }

        return nil
    }
}

class ChatChannelArchiver {
    struct ChatChannelArchiveObject: Codable {
        static let DBID = "ChatChannelArchiveObject"
        var channelsList: Data
        var channels: Data
    }
    
    static func archive(_ channelsList: TCHChannels, channels: [TCHChannel]) {
        let channelsListData = NSKeyedArchiver.archivedData(withRootObject: channelsList)
        let channelsData = NSKeyedArchiver.archivedData(withRootObject: channels)
        let model = ChatChannelArchiveObject(channelsList: channelsListData, channels: channelsData)
        CodableManager.shared.saveModelFor(key: ChatChannelArchiveObject.DBID, model: model)
        
    }
    
    static func restore() -> ( channelsList: TCHChannels, channels: [TCHChannel])? {
        if let model: ChatChannelArchiveObject = CodableManager.shared.getModelFor(key: ChatChannelArchiveObject.DBID)  {
            let channelsList = NSKeyedUnarchiver.unarchiveObject(with: model.channelsList) as! TCHChannels
            let channels = NSKeyedUnarchiver.unarchiveObject(with: model.channels) as! [TCHChannel]
            return (channelsList, channels)
        }
        
        return nil
    }
}

class ChatChannelManager: NSObject {
    static let shared = ChatChannelManager()    
    weak var delegate:ChatChannelManagerDelegate?
    
    
    var channelsList:TCHChannels?
    var channels:[TCHChannel]? {
        didSet {
            if self.delegate != nil {
                self.delegate!.channelsUpdated()
            }
        }
    }
    
    func channels(for roomType: ChannelRoomType) ->[TCHChannel]? {
        
        return channels?.sorted(by: { (a, b) -> Bool in
            (a.lastMessageDate ?? Date()) > (b.lastMessageDate ?? Date())
        })
        
        if roomType == .host {
            let arr = channels?.filter({
                let contains = $0.uniqueName?.contains(roomType.rawValue)
                return contains ?? false
            })
            
            return arr
        }
        switch roomType {
        case .host:
                let arr = channels?.filter({
                    let contains = $0.uniqueName?.contains(roomType.rawValue)
                    return contains ?? false
                })
                
                return arr
        case .seller:
                let arr = channels?.filter({
                    let components = $0.uniqueName?.components(separatedBy: AppCommonParams.channelSeparator1)
                    let contains = $0.uniqueName?.contains(ChannelRoomType.host.rawValue)
                    return components?.first == AppManager.shared.currentUser?.chatUserId && !(contains ?? false)
                })
                
                return arr
            case .buyer:
            let arr = channels?.filter({
                var components = $0.uniqueName?.components(separatedBy: AppCommonParams.channelSeparator1)
                components = components?.last?.components(separatedBy: AppCommonParams.channelSeparator2)
                let contains = $0.uniqueName?.contains(ChannelRoomType.host.rawValue)
                return components?.first == AppManager.shared.currentUser?.chatUserId && !(contains ?? false)
            })
            
            return arr
        }
    }
    
    
    override init() {
        super.init()
        channels = [TCHChannel]()
    }
    
    // MARK: - Populate channels
    
    func populateChannels(needReload: Bool = true) {
        if needReload {
            channels = [TCHChannel]()
        }
        if let result = ChatChannelArchiver.restore() {
            channelsList = result.channelsList
            channels = result.channels
        }
        
        channelsList?.userChannelDescriptors { result, paginator in
            if let paginator = paginator {
           self.loadChannels(paginator: paginator)
            } else {
                if self.delegate != nil {
                    self.delegate!.channelsUpdated()
                }
            }
            
        }
    }
    func loadChannels(paginator: TCHChannelDescriptorPaginator) {
        if paginator.hasNextPage() {
            paginator.requestNextPage { (result, paginator) in
                if paginator != nil {
                    self.loadChannels(paginator: paginator!)
                }
            }
        }
        
        paginator.items().forEach({
            $0.channel { (result, channel) in
                if channel != nil {
                    if !(self.channels?.contains(channel!) ?? true) {
                        self.channels?.append(channel!)
                    }
                }
            }
        })
        
        if self.delegate != nil {
            self.delegate!.channelsUpdated()
        }

        self.sortChannels()
        
        self.channels?.forEach({
            $0.loadUsers()
        })
        
        if self.delegate != nil {
            self.delegate!.channelsUpdated()
        }
    }
    
    func sortChannels() {
//        let sortSelector = #selector(NSString.localizedCaseInsensitiveCompare(_:))
//        let descriptor = NSSortDescriptor(key: "friendlyName", ascending: true, selector: sortSelector)
        channels?.sort(by: { (a, b) -> Bool in
            (a.dateCreated ?? "") < (b.dateCreated ?? "")
        })
    }
    //MARK: - Delete Channel
    func remove(channel: TCHChannel, completion: @escaping ()->()) {
        channel.destroy { result in
            if (result.isSuccessful()) {
                completion()
            }
            else {
                print("You can not delete this channel")
                channel.leave(completion: { (result) in
                    if (result.isSuccessful()) {
                        completion()
                    }
                    else {
                        print("You can not leave this channel")
                        channel.declineInvitation(completion: { (result) in
                            if (result.isSuccessful()) {
                                completion()
                            }
                            else {
                                print("You can not decline Invitation this channel")
                                completion()
                            }
                        })
                    }
                })
                
            }
        }
    }
    // MARK: - Create channel
    
    func createChannel(with attributes: String, uniqueName: String, completion: @escaping (Bool, TCHChannel?) -> Void) {
        let channelOptions = [
            TCHChannelOptionAttributes: attributes,
            TCHChannelOptionUniqueName: uniqueName,
            TCHChannelOptionType: TCHChannelType.private.rawValue
        ] as [String : Any]
        UIApplication.shared.isNetworkActivityIndicatorVisible = true;
        self.channelsList?.createChannel(options: channelOptions) { result, channel in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if channel != nil {
                if !(self.channels?.contains(channel!) ?? true) {
                    self.channels?.append(channel!)
                }
            }
            print(result)
            completion((result.isSuccessful()), channel)
        }
    }
    func channel(with attributes: String, uniqueName: String, completion: @escaping (Bool, TCHChannel?) -> Void) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true;
        
        if let channel = channelsList?.subscribedChannels().first(where: {
            ($0 as TCHChannel).uniqueName == uniqueName
        }) {
            channel.setAttributes(TCHJsonAttributes(string: attributes), completion: { (result) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                completion((result.isSuccessful()), channel)
            })
            return
        }
        
        self.channelsList?.channel(withSidOrUniqueName: uniqueName, completion: { (result, channel) in
            if result.isSuccessful() {
                channel?.setAttributes(TCHJsonAttributes(string: attributes), completion: { (result) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    completion((result.isSuccessful()), channel)
                })
            } else {
                
                self.createChannel(with :attributes, uniqueName: uniqueName, completion: completion)
            }
        })
    }
    
    func fetchChannel(uniqueName: String, completion: @escaping (Bool, TCHChannel?) -> Void) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true;
        
        if let channel = channelsList?.subscribedChannels().first(where: {
            ($0 as TCHChannel).uniqueName == uniqueName
        }) {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                completion(true, channel)
            return
        }
        
        self.channelsList?.channel(withSidOrUniqueName: uniqueName, completion: { (result, channel) in
            if result.isSuccessful() {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    completion((result.isSuccessful()), channel)
            } else {
                completion(false, nil)
                
            }
        })
    }
    
    func channel(for cid: String, completion: @escaping (Bool, TCHChannel?) -> Void) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true;
        
        
        self.channelsList?.channel(withSidOrUniqueName: cid, completion: { (result, channel) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                completion((result.isSuccessful()), channel)
        })
    }
}

// MARK: - TwilioChatClientDelegate
extension ChatChannelManager : TwilioChatClientDelegate {
    func chatClient(_ client: TwilioChatClient, channelAdded channel: TCHChannel) {
        DispatchQueue.main.async {
            if self.channels != nil {
                if !(self.channels!.contains(channel)) {
                        self.channels!.append(channel)
                    }
                self.sortChannels()
            }
            self.delegate?.channelsUpdated()
        }
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, updated: TCHChannelUpdate) {
        self.delegate?.channelsUpdated()
    }
    
    func chatClient(_ client: TwilioChatClient, channelDeleted channel: TCHChannel) {
        DispatchQueue.main.async {
            if self.channels != nil {
                self.channels?.removeAll(channel)
            }
            self.delegate?.channelsUpdated()
        }
        
    }
    
    func chatClient(_ client: TwilioChatClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
    }
}

protocol ChatChannelManagerDelegate: class {
    func channelsUpdated()
}
