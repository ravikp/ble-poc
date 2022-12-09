//
//  Cryptography.swift
//  bluetoothdemo
//
//  Created by Alka Prasad on 07/12/22.
//

import Foundation
import CryptoKit

class CipherBox{
    let symmetricKey:  SymmetricKey
    let nonceData = Data([0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0])
    
    init(symmetricKey: SymmetricKey){
        self.symmetricKey = symmetricKey
    }
    
    func encrypt(message: String) -> Data{
        let messageData = message.data(using: .utf8)!
        print("Plain Text Message: \(messageData.toHex())")
        let encryptedSealedBox = try! AES.GCM.seal(messageData, using: symmetricKey,nonce: AES.GCM.Nonce(data: nonceData))
        let cipherWithAuthTag = encryptedSealedBox.ciphertext + encryptedSealedBox.tag
        print("Encrypted Message with tag: \(cipherWithAuthTag.toHex())")
        return cipherWithAuthTag
        }
    
    func decrypt(encryptedMessage: [UInt8]) -> String{
        print("Encrypted Message with tag: \(encryptedMessage)")
        let cipherMessage = encryptedMessage.dropLast(16)
        let  cipherTag = encryptedMessage.suffix(16)
        let sealedBox = try! AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: nonceData), ciphertext: cipherMessage, tag: cipherTag)
        let decryptedData = try! AES.GCM.open(sealedBox, using: symmetricKey)
        print("Plain Text Message: \(decryptedData.toHex())")
        return String(data: decryptedData, encoding: .utf8)!
    }
}

extension Data {
    func toHex()->String{
        return self.map{ String(format: "%02x", $0)}.joined()
    }
}

extension SharedSecret {
    func toData()-> Data{
        return self.withUnsafeBytes{Data(Array($0))}
    }
}

extension SymmetricKey {
    func toData()-> Data{
        return self.withUnsafeBytes{Data(Array($0))}
    }
}



