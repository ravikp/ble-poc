//
//  CryptoBox.swift
//  bluetoothdemo
//
//  Created by ShreeThaanu on 16/12/22.
//

import Foundation
import CryptoKit

protocol CryptoBoxProtocol {
    func createCipherPackage(otherPublicKey : Data, senderInfo: String, receiverInfo:String, ivBytes: Data) -> CipherPackage
    func getPublicKey() -> Data
}
