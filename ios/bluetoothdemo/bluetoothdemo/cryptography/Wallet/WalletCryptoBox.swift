//
//  WalletCryptoBox.swift
//  bluetoothdemo
//
//  Created by ShreeThaanu on 19/12/22.
//

import Foundation
import CryptoKit

protocol WalletCryptoBox {
    func buildSecretsTranslator(verifierPublicKey: Data) -> SecretsTranslator
    func getPublicKey() -> Data
}
