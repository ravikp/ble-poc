//
//  KeyGenerator.swift
//  bluetoothdemo
//
//  Created by ShreeThaanu on 16/12/22.
//

import Foundation
import CryptoKit

class KeyGenerator {

    func generateStrongKeyBasedOnHKDF(sharedSecretKey: SharedSecret, keyLength: Int, infoData: String) -> SymmetricKey {
        let salt = Data([0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c])
        let sharedInfo = infoData.data(using: .utf8)
        let strongKey = sharedSecretKey.hkdfDerivedSymmetricKey(using: SHA256.self, salt: salt, sharedInfo: sharedInfo!, outputByteCount: keyLength)
        return strongKey
    }
}
