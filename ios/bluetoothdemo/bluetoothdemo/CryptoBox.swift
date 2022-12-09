//
//  CryptoBox.swift
//  bluetoothdemo
//
//  Created by Alka Prasad on 07/12/22.
//

import Foundation
import CryptoKit

class CryptoBox {
    
    let privateKey = Curve25519.KeyAgreement.PrivateKey()
      
      func getPublicKey() -> Curve25519.KeyAgreement.PublicKey{
          return privateKey.publicKey
      }
      
      func createCipherBox(data : Data) -> CipherBox{
          let sharedPublicKey = try! Curve25519.KeyAgreement.PublicKey(rawRepresentation: data)
          print("Shared Public Key: \(sharedPublicKey.rawRepresentation.toHex())")
          let weakKey = try! privateKey.sharedSecretFromKeyAgreement(with: sharedPublicKey)
          print("Weak Key: \(weakKey.toData().toHex())")
          let strongKey = generateStrongKeyBasedOnHKDF(sharedSecretKey: weakKey)
          print("Strong Key: \(strongKey.toData().toHex())")
          return CipherBox(symmetricKey: strongKey)
      }
      
      func generateStrongKeyBasedOnHKDF(sharedSecretKey: SharedSecret) -> SymmetricKey{
          let  salt = Data([0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c])
          let sharedInfo = Data([0xF0, 0xF1,0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7, 0xF8, 0xF9])
          let strongKey = sharedSecretKey.hkdfDerivedSymmetricKey(using: SHA256.self, salt: salt, sharedInfo: sharedInfo, outputByteCount: 32)
          return strongKey
      }
        
}



