//
//  ChatChannelsController.swift
//  Vayn_Chat
//
//  Created by Sargis Gevorgyan on 4/21/20.
//  Copyright © 2020 MagicDevs. All rights reserved.
//

import UIKit
import TwilioChatClient

class ChatChannelsController: BaseViewController {
    static let TWCOpenChannelSegue = "OpenChat"
    static let TWCRefreshControlXOffset: CGFloat = 120
    
    @IBOutlet var emptyView: EmptyView!
    
    var type = ChannelRoomType.seller {
        didSet {
            configureType()
        }
    }
    
    private var canShowLoadingCell: Bool {
        return (ChatChannelManager.shared.channels == nil)
    }
    
    var channels: [TCHChannel] {
        return ChatChannelManager.shared.channels(for: type) ?? []
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
         
        configureParams()
    }
    
    func configureParams() {
        
        refreshControl = AppRefreshControl()
        tableView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(ChatChannelsController.pullToRefresh), for: .valueChanged)
        refreshControl.tintColor = UIColor.primaryColor
        tableView.contentInset.top = 23.scaled
        
        tableView.register(UINib.init(nibName: LoadingTableViewCell.id, bundle: nil), forCellReuseIdentifier: LoadingTableViewCell.id)
        tableView.register(UINib.init(nibName: ChannelCell.id, bundle: nil), forCellReuseIdentifier: ChannelCell.id)
        
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.refreshControl = refreshControl
        tableView.estimatedRowHeight = 500.scaled
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset.bottom = 25.scaled
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        
        self.refreshControl.frame.origin.x -= ChatChannelsController.TWCRefreshControlXOffset
        if let chatUserName = AppManager.shared.currentUser?.chatUserName {
            ChatManager.shared.connectChat(username:chatUserName ) {
                ChatChannelManager.shared.delegate = self
                ChatChannelManager.shared.populateChannels(needReload: false)
                self.reloadChannelList()
            }
        }
        
        updateTitleView(title: "title_chat_channels".localize(), subtitle: nil)
        
        navigationController?.configureParamsForWhiteStyle(hideShadow: false)
        if AppTarget.current == .tekramChat {
        } else {
            createMenuButton()
        }
        
        configureType()
    }
    
    func configureType() {
        switch type {
        case .seller:
            emptyView?.type = .chatSellers
        case .buyer:
            emptyView?.type = .chatBuyers
        case .host:
            emptyView?.type = .chatHosts
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshChannels()
        reloadChannelList()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Internal methods
    func reloadData() {
        reloadChannelList()
    }
    
    @objc func pullToRefresh() {
        refreshChannels(needReload: true)
    }
    
    func channelCellForTableView(tableView: UITableView, atIndexPath indexPath: IndexPath) -> ChannelCell {
        let menuCell = tableView.dequeueReusableCell(withIdentifier: ChannelCell.id, for: indexPath as IndexPath) as! ChannelCell
        menuCell.indexPath = indexPath
        
        let channel = channels[indexPath.section]
        
        menuCell.model = nil
        
        if let attr = channel.attributes() {
            if attr.isString {
                let channelModel = ChannelNameModel.parse(from: attr.string!)
                menuCell.model = channelModel
            } else {
                       print("d1")
                   }
        } else {
            print("d2")
        }
        menuCell.backgroundColor = .clear
        menuCell.contentView.backgroundColor = .clear
        menuCell.didDelete = {indPath in
            self.removeChannel(for: indPath)
        }
        
        return menuCell
    }
    
    func reloadChannelList() {
        tableView.reloadData()
        refreshControl.endRefreshing()
        
        emptyView.isHidden = channels.count > 0
    }
    
    @objc func refreshChannels(needReload:Bool = false) {
        refreshControl.beginRefreshing()
        ChatChannelManager.shared.populateChannels(needReload: needReload)
    }
    
    func deselectSelectedChannel() {
        let selectedRow = tableView.indexPathForSelectedRow
        if let row = selectedRow {
            tableView.deselectRow(at: row, animated: true)
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ChatChannelsController.TWCOpenChannelSegue {
            let indexPath = sender as! NSIndexPath
            let channel = channels[indexPath.section]
            
            let viewController = segue.destination as! AppChatViewController
            
            viewController.channelMessages.channel = channel
        }
    }
}

// MARK: - UITableViewDataSource
extension ChatChannelsController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        var count = channels.count
        if count == 0 && canShowLoadingCell {
            count = 1
        }
        return count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section >= channels.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: LoadingTableViewCell.id, for: indexPath) as! LoadingTableViewCell
            cell.indicator.startAnimating()
        cell.separatorView.isHidden = true
            return cell
        }

        let cell = channelCellForTableView(tableView: tableView, atIndexPath: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return false
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        5.scaled
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        5.scaled
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    fileprivate func removeChannel(for indexPath:IndexPath) {
        
        let alertController = UIAlertController(title: "title_are_you_sure_delete".localize(), message: nil, preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes".localize(), style: .destructive, handler: { action in
            self.deleteChannel(forRowAt: indexPath)
        })
        let cancelAction = UIAlertAction(title: "Cancel".localize(), style: .default, handler: { action in
            
        })
        alertController.addAction(cancelAction)
        alertController.addAction(yesAction)
        
        alertController.show()
    }
    
    func deleteChannel(forRowAt indexPath: IndexPath) {
        
        let channel = channels[indexPath.section]
        channel.remove {
            self.refreshChannels(needReload: true)
        }
    }
}

// MARK: - UITableViewDelegate
extension ChatChannelsController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section >= channels.count {
            print("NO Channels")
            return
        }
        performSegue(withIdentifier: ChatChannelsController.TWCOpenChannelSegue, sender: indexPath)
    }
}

// MARK: - TwilioChatClientDelegate
extension ChatChannelsController : ChatChannelManagerDelegate {
    func channelsUpdated() {
        DispatchQueue.main.async {
            self.reloadChannelList()
        }
    }
}

