//
//  ChatView.swift
//  bluetoothdemo
//
//  Created by Shaik mohammed Jaffer on 18/11/22.
//

import SwiftUI

struct ChatView: View {
    @State var typingMessage: String = ""
    @Binding var messages: [Message]
    let user: User?
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(messages, id: \.id) { msg in
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
            }.navigationBarTitle(("User 1"), displayMode: .inline)
        }
    }
    
    func sendMessage() {
        typingMessage = ""
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(messages: .constant([]), user: User(name: "TESTUSER_1"))
    }
}
