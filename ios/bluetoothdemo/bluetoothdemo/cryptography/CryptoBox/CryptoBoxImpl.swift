

import Foundation
import CryptoKit

class CryptoBoxImpl: CryptoBoxProtocol {

    var privateKey: Curve25519.KeyAgreement.PrivateKey

    init() {
        self.privateKey = Curve25519.KeyAgreement.PrivateKey()
    }

    func getPublicKey() -> Data {
        return privateKey.publicKey.rawRepresentation
    }

    func createCipherPackage(otherPublicKey: Data, senderInfo: String, receiverInfo: String, ivBytes: Data) -> CipherPackage {
        let sharedPublicKey = try! Curve25519.KeyAgreement.PublicKey(rawRepresentation: otherPublicKey)
        print("Shared Public Key: \(sharedPublicKey.rawRepresentation.toHex())")

        let weakKey = try! privateKey.sharedSecretFromKeyAgreement(with: sharedPublicKey)
        print("Weak Key: \(weakKey.toData().toHex())")

        let strongKey = KeyGenerator().generateStrongKeyBasedOnHKDF(sharedSecretKey: weakKey, keyLength: CryptoConstants.SECRET_LENGTH, infoData: senderInfo)
        print("Strong Key: \(strongKey.toData().toHex())")

        let senderKey = KeyGenerator().generateStrongKeyBasedOnHKDF(sharedSecretKey: weakKey, keyLength: CryptoConstants.SECRET_LENGTH, infoData: senderInfo);

        let receiverKey = KeyGenerator().generateStrongKeyBasedOnHKDF(sharedSecretKey: weakKey, keyLength: CryptoConstants.SECRET_LENGTH, infoData: receiverInfo);

        let myselfCipherPackage = CipherBoxImpl(secretKey: senderKey,
                                                initializationVector: ivBytes,
                                                digestSizeInBytes: CryptoConstants.NUMBER_OF_MAC_BYTES)
        let otherCipherPackage = CipherBoxImpl(secretKey: receiverKey,
                                               initializationVector: ivBytes,
                                               digestSizeInBytes: CryptoConstants.NUMBER_OF_MAC_BYTES)
        return CipherPackage(myself: myselfCipherPackage,
                             other: otherCipherPackage)
    }
}



