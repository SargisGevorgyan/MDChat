/*
 MIT License
 
 Copyright (c) 2017-2019 MessageKit
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import UIKit
import MapKit
import MessageKit
import InputBarAccessoryView

final class AppChatViewController: ChatViewController {
    
    let outgoingAvatarOverlap: CGFloat = 17.5
    
    
    func configureParams() {
        if #available(iOS 13.0, *) {
            self.overrideUserInterfaceStyle = .light
        }
        messagesCollectionView = MessagesCollectionView(frame: .zero, collectionViewLayout: CustomMessagesFlowLayout())
        messagesCollectionView.register(ChatDateHeaderCell.self)
        super.viewDidLoad()
        
        messagesCollectionView.backgroundColor = ChatConfigs.UIConfigs.backgroundColor
        additionalBottomInset = 15
        scrollsToBottomOnKeyboardBeginsEditing = true
        
    }
    
    override func viewDidLoad() {
        configureParams()
        addObservers()
    }
    
    fileprivate  func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }
    
    fileprivate  func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc fileprivate func applicationDidBecomeActive() {
        
    }
    
    @objc fileprivate func applicationDidEnterBackground() {
        
        
    }
    
    func back() {
        navigationController?.popViewController(animated: true)
        removeObservers()
    }
    
    override func loadMoreMessages() {
        
    }
    
    override func configureMessageCollectionView() {
        super.configureMessageCollectionView()
        
        let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
        layout?.sectionInset = UIEdgeInsets(top: 1, left: 8, bottom: 1, right: 8)
        layout?.textMessageSizeCalculator.messageLabelFont = ChatConfigs.UIConfigs.messageFont
        
        let val: CGFloat = 4
        let topCal: CGFloat = 10
        layout?.textMessageSizeCalculator.outgoingMessageLabelInsets = UIEdgeInsets(top: topCal, left: 7*val, bottom: 2*topCal, right: val)
        layout?.textMessageSizeCalculator.incomingMessageLabelInsets = UIEdgeInsets(top: topCal, left: val, bottom: 2*topCal+4, right: 5*val)
        
        let leadingMargin: CGFloat = 18
        
        //Top
        layout?.setMessageOutgoingMessageTopLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: leadingMargin)))
        layout?.setMessageIncomingMessageTopLabelAlignment(LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: leadingMargin, bottom: 0
                                                                                                                         , right: 0)))
        
        //Center
        layout?.attributedTextMessageSizeCalculator.messageLabelFont = ChatConfigs.UIConfigs.messageFont
        layout?.setMessageOutgoingMessagePadding(UIEdgeInsets(top: 0, left: 0, bottom: -2*topCal, right: leadingMargin))
        layout?.setMessageIncomingMessagePadding(UIEdgeInsets(top: 0, left: leadingMargin, bottom: -2*topCal, right: 0))
        layout?.attributedTextMessageSizeCalculator.outgoingMessageLabelInsets = UIEdgeInsets(top: topCal, left: 5*val, bottom: 2*topCal, right: val)
        layout?.attributedTextMessageSizeCalculator.incomingMessageLabelInsets = UIEdgeInsets(top: topCal, left: val, bottom: 2*topCal, right: 2*val)
        
        //Bottom
        layout?.setMessageOutgoingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: leadingMargin + 4)))
        layout?.setMessageIncomingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: leadingMargin + 4, bottom: 0, right:0)))
        
        //Avatar
        // Hide the outgoing avatar and adjust the label alignment to line up with the messages
        layout?.setMessageOutgoingAvatarSize(.zero)
        layout?.setMessageOutgoingAvatarPosition(AvatarPosition(horizontal: .cellTrailing, vertical: .cellTop))
        
        // Set outgoing avatar to overlap with the message bubble
        layout?.setMessageIncomingAvatarSize(.zero)
        layout?.setMessageIncomingAvatarPosition(AvatarPosition(horizontal: .cellLeading, vertical: .cellTop))
        //        layout?.setAvatarLeadingTrailingPadding(20.0)
        
        //AccessoryView
        layout?.setMessageOutgoingAccessoryViewSize(CGSize(width: 30, height: 30))
        layout?.setMessageOutgoingAccessoryViewPadding(HorizontalEdgeInsets(left: 0, right: 8))
        layout?.setMessageIncomingAccessoryViewSize(CGSize(width: 30, height: 30))
        layout?.setMessageIncomingAccessoryViewPadding(HorizontalEdgeInsets(left: 8, right: 0))
        layout?.setMessageOutgoingAccessoryViewPosition(.messageBottom)
        layout?.setMessageIncomingAccessoryViewPosition(.messageBottom)
        
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
    
    override func configureMessageInputBar() {
        super.configureMessageInputBar()
        
        messageInputBar.isTranslucent = false
        messageInputBar.separatorLine.isHidden = true
        messageInputBar.inputTextView.tintColor = ChatConfigs.UIConfigs.mainThemeColor
        messageInputBar.inputTextView.font = ChatConfigs.UIConfigs.messageFont
        messageInputBar.inputTextView.isImagePasteEnabled = false
        messageInputBar.inputTextView.backgroundColor = ChatConfigs.UIConfigs.inputViewBackgroundColor
        messageInputBar.inputTextView.placeholderTextColor = ChatConfigs.UIConfigs.inputViewPlaceHolderColor
        messageInputBar.inputTextView.placeholder = ChatConfigs.UIConfigs.inputViewPlaceHodler
        messageInputBar.inputTextView.placeholderLabel.font = messageInputBar.inputTextView.font
        messageInputBar.inputTextView.layer.cornerRadius = 16
        messageInputBar.inputTextView.layer.masksToBounds = true
        
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 11, left: 10, bottom: 8, right: 13)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 11, left: 15, bottom: 8, right: 13)
        
        messageInputBar.layer.borderColor = ChatConfigs.UIConfigs.mainThemeColor.cgColor
        messageInputBar.layer.borderWidth = 1.0
        messageInputBar.layer.masksToBounds = false
        messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        configureInputBarItems()
        messageInputBar.layer.shadowColor = ChatConfigs.UIConfigs.mainThemeColor.cgColor
        messageInputBar.layer.shadowOffset = CGSize(width: 0, height: -1)
        messageInputBar.layer.shadowRadius = 10
        view.layoutIfNeeded()
    }
    
    private func configureInputBarItems() {
        messageInputBar.sendButton.titleLabel?.font = ChatConfigs.UIConfigs.inputViewSendButtonFont
        
        messageInputBar.setRightStackViewWidthConstant(to: 85, animated: false)
        messageInputBar.sendButton.backgroundColor = ChatConfigs.UIConfigs.mainThemeColor.withAlphaComponent(0.5)
        messageInputBar.sendButton.contentEdgeInsets = .zero
        messageInputBar.sendButton.setSize(CGSize(width: 35, height: 35), animated: false)
        messageInputBar.sendButton.image = nil
        messageInputBar.sendButton.title = ChatConfigs.UIConfigs.inoutViewSendButtonTitle
        messageInputBar.sendButton.setTitleColor(.white, for: .normal)
        messageInputBar.sendButton.setTitleColor(UIColor.white.withAlphaComponent(0.8), for: .highlighted)
        messageInputBar.sendButton.setTitleColor(UIColor.white.withAlphaComponent(0.8), for: .disabled)
        messageInputBar.sendButton.layer.cornerRadius = 17.5
        messageInputBar.backgroundColor = .white
        messageInputBar.tintColor = .white
        
        let attachmentButton = InputBarButtonItem()
            .configure { (item) in
                item.title = "" //AppCommonParams.paperClip
                item.titleLabel?.font = ChatConfigs.UIConfigs.inputViewSendButtonFont
                item.setTitleColor(ChatConfigs.UIConfigs.controllerTitleColor, for: .normal)
                item.setTitleColor(ChatConfigs.UIConfigs.controllerTitleColor.withAlphaComponent(0.8), for: .highlighted)
                item.setSize(CGSize(width: 35, height: 35), animated: false)
            } .onTouchUpInside { (item) in
                //TODO: sent attachment
            }
        messageInputBar.setStackViewItems([attachmentButton, messageInputBar.sendButton], forStack: .right, animated: false)
        messageInputBar.rightStackView.spacing = 15
        configureInputBarPadding()
        
        // This just adds some more flare
        messageInputBar.sendButton
            .onEnabled { item in
                UIView.animate(withDuration: 0.3, animations: {
                    item.backgroundColor = ChatConfigs.UIConfigs.mainThemeColor
                })
            }.onDisabled { item in
                UIView.animate(withDuration: 0.3, animations: {
                    item.backgroundColor = ChatConfigs.UIConfigs.mainThemeColor.withAlphaComponent(0.5)
                })
            }
    }
    
    private func configureInputBarPadding() {
        
        // Entire InputBar padding
        messageInputBar.middleContentViewPadding.top = (UIDevice.isIphoneX ? 5 : 1.5)
        
        // or MiddleContentView padding
        messageInputBar.middleContentViewPadding.right = -39.scaled
        
        // or InputTextView padding
        messageInputBar.inputTextView.textContainerInset.bottom = 8.scaled
        
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        
        return .lightContent
    }
    
    // MARK: - Helpers
    
    func setTypingIndicatorViewHidden(_ isHidden: Bool, performUpdates updates: (() -> Void)? = nil) {
        
        setTypingIndicatorViewHidden(isHidden, animated: true, whilePerforming: updates) { [weak self] success in
            if success, self?.isLastSectionVisible() == true {
                self?.messagesCollectionView.scrollToBottom(animated: true)
            }
        }
    }
    
    private func makeButton(named: String) -> InputBarButtonItem {
        return InputBarButtonItem()
            .configure {
                $0.spacing = .fixed(10)
                $0.image = UIImage(named: named)?.withRenderingMode(.alwaysTemplate)
                $0.setSize(CGSize(width: 25, height: 25), animated: false)
                $0.tintColor = UIColor(white: 0.8, alpha: 1)
            }.onSelected {
                $0.tintColor = .primaryColor
            }.onDeselected {
                $0.tintColor = UIColor(white: 0.8, alpha: 1)
            }.onTouchUpInside {
                print("Item Tapped")
                let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                let action = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                actionSheet.addAction(action)
                if let popoverPresentationController = actionSheet.popoverPresentationController {
                    popoverPresentationController.sourceView = $0
                    popoverPresentationController.sourceRect = $0.frame
                }
                self.navigationController?.present(actionSheet, animated: true, completion: nil)
            }
    }
    
    // MARK: - UICollectionViewDataSource
    
    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
            fatalError("Ouch. nil data source for messages")
        }
        
        // Very important to check this when overriding `cellForItemAt`
        // Super method will handle returning the typing indicator cell
        guard !isSectionReservedForTypingIndicator(indexPath.section) else {
            return super.collectionView(collectionView, cellForItemAt: indexPath)
        }
        
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        if case .custom = message.kind {
            let cell = messagesCollectionView.dequeueReusableCell(ChatDateHeaderCell.self, for: indexPath)
            
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            return cell
        }
        if let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as?TextMessageCell {
            
            cell.messageLabel.font = .appRegularFont(pointSize: 13.6)
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            
            cell.messageBottomLabel.superview?.bringSubviewToFront(cell.messageBottomLabel)
            
            return cell
        }
        return  super.collectionView(collectionView, cellForItemAt: indexPath)
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if  cell is TextMessageCell {
            let tCell = cell as! TextMessageCell
            
            tCell.messageBottomLabel.superview?.bringSubviewToFront(tCell.messageBottomLabel)
            
        }
    }
    // MARK: - MessagesDataSource
    
    override func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        //        if isTimeLabelVisible(at: indexPath) {
        //            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        //        }
        return nil
    }
    
    override func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        //        if !isPreviousMessageSameSender(at: indexPath) {
        //            let strDate = message.sentDate.hourMinWithDateTimeIndicator.uppercased() // + " :\(message.sentDate.second) :\(message.sentDate.millisecond)"
        //            return NSAttributedString(string: strDate, attributes: [NSAttributedString.Key.font: UIFont.appRegularFont(pointSize: 10.8),
        //                                                                    NSAttributedString.Key.foregroundColor: UIColor.AppTitleColor])
        //        }
        return nil
    }
    
    override func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        let strDate = message.sentDate.hourMinWithDateTimeIndicator.uppercased() // + " :\(message.sentDate.second) :\(message.sentDate.millisecond)"
        let attr = NSMutableAttributedString(string: strDate, attributes: [NSAttributedString.Key.font: UIFont.appRegularFont(pointSize: 7.5),
                                                                           NSAttributedString.Key.foregroundColor: UIColor.AppTextColor])
        
        if isFromCurrentSender(message: message) {
            let checkAttr = NSAttributedString(string: " \(AppCommonParams.checkIcon)", attributes: [NSAttributedString.Key.font: UIFont.FontAwesome5FreeSolid(pointSize: 9),
                                                                                                     NSAttributedString.Key.foregroundColor: UIColor.AppGreenColor])
            attr.append(checkAttr)
        }
        return attr
    }
    
    
    //MARK: - Input Bar Delegations
    override func textViewTextDidChangeTo(text: String) {
        super.textViewTextDidChangeTo(text: text)
//        channelMessages.typing()
    }
    
//    override func sendMessages(_ data: [Any]) {
//        channelMessages.sendMessages(data)
//    }
//
//    override func currentSender() -> SenderType {
//        return channelMessages.currentSender()
//    }
    
}

// MARK: - MessagesDisplayDelegate

extension AppChatViewController: MessagesDisplayDelegate {
    
    // MARK: - Text Messages
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return ChatConfigs.UIConfigs.controllerTitleColor
    }
    
    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {
        
        if isFromCurrentSender(message: message) {
            return [.foregroundColor: UIColor.chatDarkTextColor,
                    .font : UIFont.appRegularFont(pointSize: 13.6)]
        } else {
            return [.foregroundColor: UIColor.chatDarkTextColor,
                    .font : UIFont.appRegularFont(pointSize: 13.6)]
        }
        
    }
    
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date, .transitInformation, .mention, .hashtag]
    }
    
    // MARK: - All Messages
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return .white
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        
        var corners: UIRectCorner = []
        
        var mCorners:CACornerMask = CACornerMask()
        if isFromCurrentSender(message: message) {
            corners.formUnion(.topLeft)
            corners.formUnion(.bottomLeft)
            corners.formUnion(.bottomRight)
            mCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            corners.formUnion(.topRight)
            corners.formUnion(.bottomLeft)
            corners.formUnion(.bottomRight)
            mCorners = [.layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
        
        return .custom { view in
            let radius: CGFloat = 6
            
            //            let path = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
            //                UIColor.red.setStroke()
            //            path.lineWidth = 1.scaled
            //            path.stroke()
            //            let mask = CAShapeLayer()
            //            mask.path = path.cgPath
            //            mask.strokeColor = UIColor.red.cgColor
            //            mask.lineWidth = 1.scaled
            
            view.layer.maskedCorners = mCorners
            view.layer.borderColor = self.isFromCurrentSender(message: message) ? ChatConfigs.UIConfigs.mainThemeColor.cgColor : ChatConfigs.UIConfigs.receivedBubbleLayerColor.cgColor
            view.layer.borderWidth = 1
            view.layer.cornerRadius = radius
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        let avatar = SampleData.shared.getAvatarFor(sender: message.sender)
        avatarView.set(avatar: avatar)
        avatarView.layer.borderWidth = 0
        
        guard let user = message.sender as? MockUser else {return}
        
        #warning(" SET AVATAR HERE ")//var avatarUrl =
//        if avatarUrl.isEmpty {
//            avatarUrl = user.avatarUrl ?? ""
//        }
        avatarView.image = ChatConfigs.UIConfigs.avatarPlaceHolder
//        avatarView.setImage(avatarUrl, avatar.image ?? #imageLiteral(resourceName: "icEmptyProfile"), completion: nil)
    }
    
    func configureAccessoryView(_ accessoryView: UIView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        // Cells are reused, so only add a button here once. For real use you would need to
        // ensure any subviews are removed if not needed
        accessoryView.subviews.forEach { $0.removeFromSuperview() }
        accessoryView.backgroundColor = .clear
        
        var shouldShow = Int.random(in: 0...10) == 0
        //"es inputBarAccessoryView hanum"
        shouldShow = false
        guard shouldShow else { return }
        
        let button = UIButton(type: .infoLight)
        button.tintColor = ChatConfigs.UIConfigs.mainThemeColor
        accessoryView.addSubview(button)
        button.frame = accessoryView.bounds
        button.isUserInteractionEnabled = false // respond to accessoryView tap through `MessageCellDelegate`
        accessoryView.layer.cornerRadius = accessoryView.frame.height / 2
        accessoryView.backgroundColor = ChatConfigs.UIConfigs.mainThemeColor.withAlphaComponent(0.3)
    }
    
    // MARK: - Location Messages
    
    func annotationViewForLocation(message: MessageType, at indexPath: IndexPath, in messageCollectionView: MessagesCollectionView) -> MKAnnotationView? {
        let annotationView = MKAnnotationView(annotation: nil, reuseIdentifier: nil)
        let pinImage = #imageLiteral(resourceName: "ic_map_marker")
        annotationView.image = pinImage
        annotationView.centerOffset = CGPoint(x: 0, y: -pinImage.size.height / 2)
        return annotationView
    }
    
    func animationBlockForLocation(message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> ((UIImageView) -> Void)? {
        return { view in
            view.layer.transform = CATransform3DMakeScale(2, 2, 2)
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [], animations: {
                view.layer.transform = CATransform3DIdentity
            }, completion: nil)
        }
    }
    
    func snapshotOptionsForLocation(message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LocationMessageSnapshotOptions {
        
        return LocationMessageSnapshotOptions(showsBuildings: true, showsPointsOfInterest: true, span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
    }
    
    // MARK: - Audio Messages
    
    func audioTintColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return ChatConfigs.UIConfigs.controllerTitleColor
    }
    
    func configureAudioCell(_ cell: AudioMessageCell, message: MessageType) {
        audioController.configureAudioCell(cell, message: message) // this is needed especily when the cell is reconfigure while is playing sound
    }
}

// MARK: - MessagesLayoutDelegate

extension AppChatViewController: MessagesLayoutDelegate {
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        //        if isTimeLabelVisible(at: indexPath) {
        //            return 50
        //        }
        return 0
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 15
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        
        return 17
    }
}

extension AppChatViewController {
    func messagesInserted(messages: [MockMessage]) {
        DispatchQueue.main.async {
            self.messageList.insert(contentsOf: messages, at: 0)
            if messages.count == 0 {
                self.messagesCollectionView.reloadData()
            } else {
                self.messagesCollectionView.reloadDataAndKeepOffset()
            }
            self.refreshControl.endRefreshing()
        }
    }
    
    func channelDeleted() {
        
    }
    
    func messagesAdded(items: [MockMessage]) {
        self.messageList = items
        needReloadData()
    }
    
    func messageInserted(message: MockMessage) {
        self.insertMessage(message)
    }
    
    func clientTypingStartedOn() {
        self.setTypingIndicatorViewHidden(false)
    }
    
    func clientTypingEndedOn() {
        self.setTypingIndicatorViewHidden(true, performUpdates: {
            
        })
    }
    
    func needReloadData() {
        self.messagesCollectionView.alpha = 0.0
        UIView.animate(withDuration: 0) {
            self.messagesCollectionView.reloadData()
        } completion: { _ in
            self.messagesCollectionView.scrollToBottom(animated: false)
            self.messagesCollectionView.alpha = 1.0
        }
    }
    
    func needRebuilData(items: [MockMessage], scrollBottom: Bool) {
        self.messageList = items
        if scrollBottom {
            needReloadData()
        } else {
            self.messagesCollectionView.reloadDataAndKeepOffset()
        }
    }
}
