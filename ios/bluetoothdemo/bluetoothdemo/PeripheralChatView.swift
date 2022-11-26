//
//  PeripheralChatView.swift
//  bluetoothdemo
//
//  Created by Shaik mohammed Jaffer on 22/11/22.
//

import SwiftUI

struct PeripheralChatView: View {
    @State var typingMessage: String = ""
    @ObservedObject var controller: PeripheralController
    let user: User?
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(controller.publishedMessages, id: \.id) { msg in
                        MessageView(currentMessage: msg)
                    }
                }
                HStack {
                    TextField("Message...", text: $typingMessage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(minHeight: CGFloat(30))
                    Button(action: sendMessage) {
                        Text("Send")
                    }
                }.frame(minHeight: CGFloat(50)).padding()
            }.navigationBarTitle(("User 2"), displayMode: .inline)
        }
    }
    
    func sendMessage() {
        controller.publishedMessages.append(Message(content: typingMessage, user: User(name: "peripheral", isCurrentUser: true)))
        controller.sendData(message: typingMessage)
        typingMessage = ""
    }
}

struct PeripheralChatView_Previews: PreviewProvider {
    static var previews: some View {
       PeripheralChatView(controller: (PeripheralController()), user: User(name: "TESTUSER_1"))
    }
}


