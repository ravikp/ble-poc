//
//  SecretTranslator.swift
//  bluetoothdemo
//
//  Created by ShreeThaanu on 16/12/22.
//

import Foundation

protocol SecretsTranslator {
    func initializationVector() -> Data
    func encryptToSend(data: Data) -> Data
    func decryptUponReceive(data: Data) -> Data
}
