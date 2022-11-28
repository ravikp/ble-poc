//
//  TransferServiceController.swift
//  bluetoothdemo
//
//  Created by Shaik mohammed Jaffer on 16/11/22.
//

import Foundation
import CoreBluetooth

struct TransferService {
    static let serviceUUID = CBUUID(string: "0000AB29-0000-1000-8000-00805f9b34fb")
    static let characteristicUUID = CBUUID(string: "00002032-0000-1000-8000-00805f9b34fb")
    static let writeCharacteristic = CBUUID(string: "00002031-0000-1000-8000-00805f9b34fb")

}

