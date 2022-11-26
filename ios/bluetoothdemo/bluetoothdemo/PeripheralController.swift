//
//  PeripheralController.swift
//  bluetoothdemo
//
//  Created by Shaik mohammed Jaffer on 18/11/22.
//

import Foundation
import CoreBluetooth
import os

class PeripheralController: NSObject, ObservableObject {
    
    var peripheralManager: CBPeripheralManager!
    var transferCharacteristic: CBMutableCharacteristic?
    var connectedCentral: CBCentral?
    var dataToSend = Data()
    var peripheralUser: User?
    
    @Published var centralConnected: Bool = false
    @Published var publishedMessages: [Message] = []
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options:[CBPeripheralManagerOptionShowPowerAlertKey: true])
    }
    
    private func setupPeripheral() {
        
        let transferCharacteristic = CBMutableCharacteristic(type: TransferService.characteristicUUID, properties: [.notify, .writeWithoutResponse, .write], value: nil, permissions: [.readable, .writeable])
        
        let transferService = CBMutableService(type: TransferService.serviceUUID, primary: true)
        transferService.characteristics = [transferCharacteristic]
        
        peripheralManager.add(transferService)
        self.transferCharacteristic = transferCharacteristic
        
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [TransferService.serviceUUID]])
    }
    
    func sendData(message: String) {
        guard let transferCharacteristic = transferCharacteristic else {
            return
        }
        
        let didSend = peripheralManager.updateValue(Data(bytes: Array(message.utf8), count: message.count), for: transferCharacteristic, onSubscribedCentrals: nil)
        
        if !didSend {
            return
        }
    }
}

extension PeripheralController: CBPeripheralManagerDelegate {
    internal func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            os_log("CBPeripheral is powered ON")
            setupPeripheral()
        default:
            os_log("CBPeripheral is state \(peripheral.state.rawValue)")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        os_log("Central subscribed to characteristic")
        peripheralUser = User(name: "Peripheral", isCurrentUser: true)
        connectedCentral = central
        centralConnected = true
        peripheral.stopAdvertising()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        os_log("Central unsubscribed from characteristic")
        connectedCentral = nil
        centralConnected = false
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        os_log("Received write request for characteristic")
        print(requests.count)
        
        for request in requests {
            if let value = request.value {
                print(String(decoding: value, as: UTF8.self))
            }
        }
        for aRequest in requests {
            if let requestValue = aRequest.value,
               let stringFromData = String(data: requestValue, encoding: .utf8) {
               self.publishedMessages.append(Message(content: stringFromData, user: User(name: "Central", isCurrentUser: false)))
            }else {
                os_log("Found not data")
            }
        }
    }
}

