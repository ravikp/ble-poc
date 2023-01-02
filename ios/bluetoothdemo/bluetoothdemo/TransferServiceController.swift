//
//  TransferServiceController.swift
//  bluetoothdemo
//
//  Created by Shaik mohammed Jaffer on 16/11/22.
//

import Foundation
import CoreBluetooth

struct TransferService {
    static let identifyRequestCharacteristic = CBUUID(string: "00002030-0000-1000-8000-00805f9b34fb")
    static let requestSizeCharacteristic = CBUUID(string: "00002031-0000-1000-8000-00805f9b34fb")
    static let requestCharacteristic = CBUUID(string: "00002032-0000-1000-8000-00805f9b34fb")
    static let responseSizeCharacteristic = CBUUID(string: "00002033-0000-1000-8000-00805f9b34fb")
    static let responseCharacteristic = CBUUID(string: "00002034-0000-1000-8000-00805f9b34fb")
    static let semaphoreCharacteristic = CBUUID(string: "00002035-0000-1000-8000-00805f9b34fb")
    static let verificationStatusCharacteristic = CBUUID(string: "00002036-0000-1000-8000-00805f9b34fb")


    static let serviceUUID = CBUUID(string: "0000AB29-0000-1000-8000-00805f9b34fb") // same
    static let scanResponseServiceUUID = CBUUID(string: "0000AB2A-0000-1000-8000-00805f9b34fb")

    // older stuff
    // @deprecated
    static let characteristicUUID = CBUUID(string: "00002032-0000-1000-8000-00805f9b34fb") //read characteristics
    static let writeCharacteristic = CBUUID(string: "00002031-0000-1000-8000-00805f9b34fb")
}

let relevantPeripherals: [CBUUID] = [TransferService.serviceUUID, TransferService.scanResponseServiceUUID]

// 
let characteristicMap: [String: CBUUID] = [
    "identifyRequestCharacteristic": TransferService.identifyRequestCharacteristic,
    "requestSizeCharacteristic": TransferService.requestSizeCharacteristic,
    "requestCharacteristic": TransferService.requestCharacteristic,
    "responseSizeCharacteristic": TransferService.responseSizeCharacteristic,
    "responseCharacteristic": TransferService.responseCharacteristic,
    "semaphoreCharacteristic": TransferService.semaphoreCharacteristic,
    "verificationStatusCharacteristic": TransferService.verificationStatusCharacteristic,
]
