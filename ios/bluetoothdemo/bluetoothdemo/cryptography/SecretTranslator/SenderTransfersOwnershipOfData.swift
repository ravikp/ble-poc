//
//  SenderTransfersOwnershipOfData.swift
//  bluetoothdemo
//
//  Created by ShreeThaanu on 16/12/22.
//

import Foundation

class SenderTransfersOwnershipOfData: SecretsTranslator {

    var senderCipherBox: CipherBox
    var receiverCipherBox: CipherBox
    var initVector: Data

    init(cipherPackage: CipherPackage, initVector: Data) {
        self.senderCipherBox = cipherPackage.getSelfCipherBox
        self.receiverCipherBox = cipherPackage.getOtherCipherBox
        self.initVector = initVector
        self.senderCipherBox.printSecretKey(identifieris: "SENDER")
        self.receiverCipherBox.printSecretKey(identifieris: "RECIVER")
    }

    func initializationVector() -> Data {
        return initVector
    }

    func encryptToSend(data: Data) -> Data {
        let encrypt = (receiverCipherBox.encrypt(message: data))
        return encrypt
    }

    func decryptUponReceive(data: Data) -> Data {
        let encrypt = (senderCipherBox.decrypt(message: data))
        return encrypt
        
    }
}
