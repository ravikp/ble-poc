

import Foundation
import UIKit
import MessageKit

struct Member {
  let name: String
  let color: UIColor
}

struct Message {
  let member: Member
  let text: String
  let messageId: String
}
struct Sender: SenderType {
    var senderId: String
    var displayName: String
}

extension Message: MessageType {
    var sender: MessageKit.SenderType {
        return Sender(senderId: member.name, displayName: member.name)
    }
  var sentDate: Date {
    return Date()
  }
  
  var kind: MessageKind {
    return .text(text)
  }
}
