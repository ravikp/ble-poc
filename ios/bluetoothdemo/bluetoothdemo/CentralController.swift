//
//  CentralController.swift
//  bluetoothdemo
//
//  Created by Shaik mohammed Jaffer on 16/11/22.
//

import Foundation
import CoreBluetooth
import os

class CentralController: NSObject, ObservableObject {
    private var centralManager: CBCentralManager!
    @Published var connectedPeripheral: CBPeripheral?
    @Published var peripherals: [CBPeripheral] = []
    @Published var transferCharacteristic: CBCharacteristic?
    @Published var connectedToPeripheral = false
    @Published var connectToPeripheralError: Error?
    @Published var publishedMessages: [Message] = []
    @Published var centralUser: User?
    
    var data = Data()
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func scanForPeripherals() {
        centralManager.scanForPeripherals(withServices: [TransferService.serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func connectToPeripheral(peripheral: CBPeripheral) {
        os_log("Coonecting to peripheral")
        centralManager.connect(peripheral)
    }
    
    func writeData(message: String) {
        guard let connectedPeripheral = connectedPeripheral,
              let transferCharacteristic = transferCharacteristic
        else {
            os_log("Unable to write to periperhal")
            return
        }
        
        if connectedPeripheral.canSendWriteWithoutResponse {
            let mtu = connectedPeripheral.maximumWriteValueLength(for: .withoutResponse)
            
            let bytesToCopy: size_t = min(mtu, message.count)
            
            let messageData = Data(bytes: Array(message.utf8), count: message.count)
            
            os_log("Writing %d bytes: %s", bytesToCopy, String(describing: message))
            connectedPeripheral.writeValue(messageData, for: transferCharacteristic, type: .withoutResponse)
        }
        
        os_log("Unable to write message to peripheral")
    }
    
    func cleanup() {
        
        guard let connectedPeripheral = connectedPeripheral, case .connected = connectedPeripheral.state else { return }
        
        for service in (connectedPeripheral.services ?? [] as [CBService]) {
            for characteristic in (service.characteristics ?? [] as [CBCharacteristic]) {
                if characteristic.uuid == TransferService.characteristicUUID {
                    self.connectedPeripheral?.setNotifyValue(false, for: characteristic)
                }
            }
        }
        
        centralManager.cancelPeripheralConnection(connectedPeripheral)
    }
}


extension CentralController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Central Manager state is powered ON")
            scanForPeripherals()
        default:
            print("Central Manager is in \(central.state.rawValue)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        os_log("Appending peripheral - %@ to list", String(describing: peripheral.name))
        peripherals.append(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("Connected to peripheral: %@", String(describing: peripheral.name))
        connectedToPeripheral = true
        self.connectedPeripheral = peripheral
        peripheral.delegate = self
        centralUser = User(name: peripheral.name ?? "Central User", isCurrentUser: true)
        central.stopScan()
        peripheral.discoverServices([TransferService.serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        os_log("Peripheral disconnected")
        connectedPeripheral = nil
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        os_log("Failed to connect to peripheral: \(String(describing: error.debugDescription))")
        connectToPeripheralError = error
        connectedToPeripheral = false
    }
}

extension CentralController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            os_log("Error while discovering services: %s", error.localizedDescription)
            cleanup()
            return
        }
        
        os_log("Discovering services for \(String(describing: peripheral.name))")
        
        guard let peripheralServices = peripheral.services else { return }
        for service in peripheralServices {
            peripheral.discoverCharacteristics([TransferService.characteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            os_log("Error discovering Characteristics: %s", error.localizedDescription)
            return
        }
        
        os_log("Discovering characteristics for \(String(describing: peripheral.name))")

        guard let serviceCharacteristics = service.characteristics else { return }
        for characteristic in serviceCharacteristics where characteristic.uuid == TransferService.characteristicUUID {
            self.transferCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            os_log("Unable to recieve updates from device: %s", error.localizedDescription)
            cleanup()
            return
        }
        
        guard let characteristicData = characteristic.value,
              let stringFromData = String(data: characteristicData, encoding: .utf8) else { return }
        os_log("Received %d bytes: %s", characteristicData.count, stringFromData)
        publishedMessages.append(Message(content: stringFromData, user: User(name: "peripheral", isCurrentUser: false)))
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            os_log("Unable to write to characteristic: %@", error.localizedDescription)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        for service in invalidatedServices where service.uuid == TransferService.serviceUUID {
            os_log("Transfer service is invalidated - rediscover services")
            peripheral.discoverServices([TransferService.serviceUUID])
        }
    }
}
