//
//  PeripheralView.swift
//  bluetoothdemo
//
//  Created by Shaik mohammed Jaffer on 21/11/22.
//

import SwiftUI

struct PeripheralView: View {
    @ObservedObject var peripheralController = PeripheralController()
    var body: some View {
        VStack {
            Text("Peripheral Screen")
                .font(.largeTitle)
                .fontWeight(.bold)
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 8)
                    .foregroundColor(.blue)
                    .opacity(0.4)
                )
            
            if !peripheralController.centralConnected {
                ProgressView()
            }
            
            NavigationView {
                NavigationLink(destination: PeripheralChatView(controller: peripheralController, user: peripheralController.peripheralUser ?? nil)) {
                    Text(peripheralController.centralConnected ? "Central is connected": "Not connected yet")
                }
            }
        }
    }
}

struct PeripheralView_Previews: PreviewProvider {
    static var previews: some View {
        PeripheralView()
    }
}
