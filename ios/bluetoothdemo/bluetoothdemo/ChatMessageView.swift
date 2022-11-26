//
//  ChatMessageView.swift
//  bluetoothdemo
//
//  Created by Shaik mohammed Jaffer on 18/11/22.
//

import SwiftUI

struct ChatMessageView: View {
    var message: String
    var isCurrentUser: Bool
    
    var body: some View {
        Text(message)
            .padding(10)
            .foregroundColor(isCurrentUser ? .white : .black)
            .background(isCurrentUser ? .blue : Color(UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0)))
            .cornerRadius(10.0)
    }
}

struct ChatMessageView_Previews: PreviewProvider {
    static var previews: some View {
        ChatMessageView(
            message: "Hey, there what's up", isCurrentUser: true
        )
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}
