//
//  Message.swift
//  bluetoothdemo
//
//  Created by Shaik mohammed Jaffer on 21/11/22.
//

import Foundation

struct Message: Hashable {
    let id: String = UUID().uuidString
    var content: String
    var user: User
}
