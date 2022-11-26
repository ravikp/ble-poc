//
//  User.swift
//  bluetoothdemo
//
//  Created by Shaik mohammed Jaffer on 21/11/22.
//

import Foundation

struct User: Hashable {
    let id: String = UUID().uuidString
    var name: String
    var isCurrentUser: Bool = false
}
