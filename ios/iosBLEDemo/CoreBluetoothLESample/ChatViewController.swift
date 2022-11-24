//
//  ChatViewController.swift
//  CoreBluetoothLESample
//
//  Created by Harsh Vardhan on 24/11/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import MessageKit
import InputBarAccessoryView
import Combine
import os
import UIKit

protocol CentralMessage: AnyObject {
    func data(msg: String)
}

class ChatViewController: MessagesViewController {
    var messages: [Message] = []
    var member: Member!
    var other: Member!
    var push = PassthroughSubject<String, Never>()
    override func viewDidLoad() {
        super.viewDidLoad()
        member = Member(name: "Central", color: .blue)
        other = Member(name: "Peripheral", color: .red)

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messageInputBar.delegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // TODO: disconnect from peripheral? & go back to scanning?
    }
}

extension ChatViewController: MessagesDataSource {
    
    
    func numberOfSections(
        in messagesCollectionView: MessagesCollectionView) -> Int {
            return messages.count
        }
    var currentSender: MessageKit.SenderType {
        return Sender(senderId: member.name, displayName: member.name)
    }
    
    
    func messageForItem(
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView) -> MessageType {
            
            return messages[indexPath.section]
        }
    
    func messageTopLabelHeight(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView) -> CGFloat {
            
            return 12
        }
    
    func messageTopLabelAttributedText(
        for message: MessageType,
        at indexPath: IndexPath) -> NSAttributedString? {
            
            return NSAttributedString(
                string: message.sender.displayName,
                attributes: [.font: UIFont.systemFont(ofSize: 12)])
        }
}

extension ChatViewController: MessagesLayoutDelegate {
    func heightForLocation(message: MessageType,
                           at indexPath: IndexPath,
                           with maxWidth: CGFloat,
                           in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        
        return 0
    }
}

extension ChatViewController: MessagesDisplayDelegate {
    func configureAvatarView(
        _ avatarView: AvatarView,
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView) {
            
            let message = messages[indexPath.section]
            let color = message.member.color
            avatarView.backgroundColor = color
        }
}


extension ChatViewController: InputBarAccessoryViewDelegate {
    @objc internal func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        processInputBar(messageInputBar)
    }
    
    private func processInputBar(_ inputBar: InputBarAccessoryView) {
        // TODO(vharsh): does incoming BLE message hit here in debugger?
        // Likely no!!
        let components = inputBar.inputTextView.components.map({ String(describing: $0)})
        // pushing data, now it's subscriber can basically read it
        push.send(inputBar.inputTextView.text)
        // now empty the bottom text box, coz message is sent(sort of like an email OutBox)
        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()
        inputBar.inputTextView.resignFirstResponder() // Resign first responder for iPad split view
        DispatchQueue.global(qos: .default).async {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {return}
                // update the UI with a nice animation
                self.insertMessages(components)
                self.messagesCollectionView.scrollToLastItem(animated: true)
                // send it across the device boundary(air) via BLE
            }
        }
    }
    
    private func insertMessages(_ data: [String]) {
        for component in data {
            //if let string = component as? String {
                let message = Message(
                    member: other,
                    text: component,
                    messageId: UUID().uuidString)
                messages.append(message)
                messagesCollectionView.reloadData()
            //}
        }
    }
}

extension ChatViewController: CentralMessage {
    func data(msg: String) {
        insertMessages([msg])
        os_log("chat msg received %s", msg)
    }
    
    
}
