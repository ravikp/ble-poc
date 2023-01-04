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
    @Published var writeCharacteristic: CBCharacteristic?
    @Published var identifyRequestCharacteristic: CBCharacteristic?
    @Published var connectedToPeripheral = false
    @Published var connectToPeripheralError: Error?
    @Published var publishedMessages: [Message] = []
    @Published var centralUser: User?
    private var cryptoBox: WalletCryptoBox?
    private var secretsTranslator: SecretsTranslator?
    
    var data = Data()
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func scanForPeripherals() {
        centralManager.scanForPeripherals(withServices: [TransferService.serviceUUID], options: [
            // the below one might be better kept as false
            // the BLE Scan resp blog suggests to keep it to True
            // but Apple's default is false
            // ref: https://uynguyen.github.io/2020/08/23/Best-practice-Advanced-BLE-scanning-process-on-iOS/
            CBCentralManagerScanOptionAllowDuplicatesKey: true,
            // ref: https://stackoverflow.com/questions/31062176/scanforperipheralswithservicesoptions-and-cbcentralmanagerscanoptionsoliciteds?rq=1
            ])
    }
    
    func connectToPeripheral(peripheral: CBPeripheral) {
        os_log("Connecting to peripheral")
        centralManager.connect(peripheral)
    }
    
    func writeData(message: String) {
        guard let connectedPeripheral = connectedPeripheral,
              let transferCharacteristic = writeCharacteristic
        else {
            os_log("Unable to write to periperhal")
            return
        }
        
        if connectedPeripheral.canSendWriteWithoutResponse {
            let mtu = connectedPeripheral.maximumWriteValueLength(for: .withoutResponse)
            let encryptedMessage = secretsTranslator?.encryptToSend(data: message.data(using: .utf8)!)
            let bytesToCopy: size_t = min(mtu, encryptedMessage!.count)
            os_log("Central: Writing %d bytes: %s with MTU: %d", bytesToCopy, String(describing: message), mtu)
            connectedPeripheral.writeValue(encryptedMessage!, for: transferCharacteristic, type: .withoutResponse)
        }
    }
    
    func sendPublicKey() {
        guard let connectedPeripheral = connectedPeripheral,
              let transferCharacteristic = identifyRequestCharacteristic
        else {
            os_log("Unable to write to periperhal")
            return
        }
        
        if connectedPeripheral.canSendWriteWithoutResponse {
            let mtu = connectedPeripheral.maximumWriteValueLength(for: .withoutResponse)
            let publicKey = cryptoBox?.getPublicKey()
            let bytesToCopy: size_t = min(mtu, publicKey?.count ?? 0)
            let initializationVector  = secretsTranslator?.initializationVector()
            let messageData = initializationVector! + publicKey!

            os_log("Central: Writing %d bytes: %s with MTU: %d", bytesToCopy, String(describing: messageData), mtu)
            connectedPeripheral.writeValue(messageData, for: transferCharacteristic, type: .withoutResponse)
        }
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
        print("Found a peripheral \(String(describing: peripheral.name)) with \(String(describing: peripheral.services)) ")
        let dataDict = advertisementData["kCBAdvDataServiceData"] as? [CBUUID: Any?]
        if let uuidDict = dataDict, let data = uuidDict[CBUUID(string: "AB2A")], let data = data {
            os_log("Appending peripheral - %@ to list", String(describing: peripheral.name))
            os_log("Scan Response data - %s", String(data: data as! Data, encoding: .utf8) ?? "No Scan Response Data")
            peripherals.append(peripheral)

            let scanResponseData = dataDict?[CBUUID(string: "AB2A")]  as! Data
            let advertisementData = dataDict?[CBUUID(string: "AB29")]  as! Data
            os_log("advertisement data -> \(advertisementData)")
            os_log("scan response data -> \(scanResponseData)")
            let publicKeyData =  advertisementData + scanResponseData
            cryptoBox = WalletCryptoBoxBuilder().build()
            secretsTranslator = (cryptoBox?.buildSecretsTranslator(verifierPublicKey: publicKeyData))!
        }
        os_log("%@", advertisementData)
        os_log("---------------------------")
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
        print("found \(String(describing: peripheral.services?.count)) services for peripheral \(String(describing: peripheral.name))")
        // os_log("Discovering services for \(String(describing: peripheral.name))")
        guard let peripheralServices = peripheral.services else { return }
        for service in peripheralServices {
            peripheral.discoverCharacteristics([TransferService.characteristicUUID, TransferService.identifyRequestCharacteristic, TransferService.writeCharacteristic], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            os_log("Error discovering Characteristics: %s", error.localizedDescription)
            return
        }
        
        os_log("Discovering characteristics for \(String(describing: peripheral.name))")

        guard let serviceCharacteristics = service.characteristics else { return }
        for characteristic in serviceCharacteristics {
            if characteristic.uuid == TransferService.characteristicUUID {
                self.transferCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.uuid == TransferService.writeCharacteristic {
                self.writeCharacteristic = characteristic
                // No notify required, right?
            }
            if characteristic.uuid == TransferService.identifyRequestCharacteristic {
                self.identifyRequestCharacteristic = characteristic
                sendPublicKey()
                print(characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            os_log("Unable to recieve updates from device: %s", error.localizedDescription)
            cleanup()
            return
        }
        guard let characteristicData = characteristic.value else {
            return
            
        }
    
        let decryptedData = secretsTranslator?.decryptUponReceive(data: characteristicData)
        publishedMessages.append(Message(content: String(decoding: decryptedData!, as: UTF8.self), user: User(name: "peripheral", isCurrentUser: false)))
        }
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
