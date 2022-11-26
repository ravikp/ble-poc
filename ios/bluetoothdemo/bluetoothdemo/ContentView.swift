//
//  ContentView.swift
//  bluetoothdemo
//
//  Created by Shaik mohammed Jaffer on 14/11/22.
//

import SwiftUI

struct ContentView: View {
    @State var isCentralClicked = false
    @State var isPeripheralClicked = false
    var body: some View {
        VStack {
            Button("Central") {
                isCentralClicked.toggle()
            }
            .buttonStyle(.borderedProminent)
            .sheet(isPresented: $isCentralClicked) {
                CentralView()
            }
            
            Spacer()
            
            Button("Peripheral") {
                isPeripheralClicked.toggle()
            }
            .buttonStyle(.borderedProminent)
            .sheet(isPresented: $isPeripheralClicked) {
                PeripheralView()
            }
            
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
