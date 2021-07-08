//
//  ChatDateHeaderCell.swift
//  Vayn_Chat
//
//  Created by Sargis Gevorgyan on 4/21/20.
//  Copyright © 2020 MagicDevs. All rights reserved.
//

import UIKit
import MessageKit

class ChatDateHeaderCell: UICollectionViewCell {
    
    let label = UILabel()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }
    
    open func setupSubviews() {
        contentView.addSubview(label)
        label.textAlignment = .center
        label.font = UIFont.appRegularFont(pointSize: 9)
        label.textColor = .AppTitleColor
        label.backgroundColor = .white
        
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        label.frame = contentView.bounds
        label.setFrameHeight(CGFloat(Int(18.scaled)))
        label.setFrameWidth(CGFloat(Int(339.scaled)))
        label.setFrameX((contentView.getFrameWidth() - label.getFrameWidth())/2)
        label.setFrameY((contentView.getFrameHeight() - label.getFrameHeight())/2)
        label.layer.cornerRadius = label.frame.height/2
        label.clipsToBounds = true
    }
    
    open func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        // Do stuff
        switch message.kind {
        case .custom(let data):
            guard let systemMessage = data as? String else { return }
            label.text = systemMessage
        default:
            break
        }
    }
    
}
