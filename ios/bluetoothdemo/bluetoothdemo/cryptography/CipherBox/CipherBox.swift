//
//  CipherBox.swift
//  bluetoothdemo
//
//  Created by ShreeThaanu on 16/12/22.


import Foundation

protocol CipherBox {
    func encrypt(message: Data) -> Data
    func decrypt(message: Data) -> Data
    func printSecretKey(identifieris: String)
}
