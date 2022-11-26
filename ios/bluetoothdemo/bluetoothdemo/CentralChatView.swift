//
//  CentralChatView.swift
//  bluetoothdemo
//
//  Created by Shaik mohammed Jaffer on 22/11/22.
//

import SwiftUI
import CoreBluetooth
import os

struct CentralChatView: View {
    @State var typingMessage: String = ""
    var controller: CentralController
    var peripheral: CBPeripheral?
    let user: User
    
    init(controller: CentralController, peripheral: CBPeripheral? = nil, user: User) {
        os_log("running init")
        self.controller = controller
        self.peripheral = peripheral
        self.user = user
    }
        
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
            }.navigationBarTitle(("User 1"), displayMode: .inline)
        }
        .onAppear {
            controller.connectToPeripheral(peripheral: peripheral!)
        }
    }
    
    func sendMessage() {
        controller.publishedMessages.append(Message(content: typingMessage, user: controller.centralUser!))
        controller.writeData(message: typingMessage)
        typingMessage = ""
    }
}

struct CentralChatView_Previews: PreviewProvider {
    static var previews: some View {
        CentralChatView(controller: CentralController(), user: User(name: "Jaffer"))
    }
}

