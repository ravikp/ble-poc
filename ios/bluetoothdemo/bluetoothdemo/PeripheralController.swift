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
    var readCharacteristic: CBMutableCharacteristic?
    var writeCharacteristic: CBMutableCharacteristic?
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
        let transferService = CBMutableService(type: TransferService.serviceUUID, primary: true)
        let scanRespService = CBMutableService(type: TransferService.scanResponseServiceUUID, primary: true)
        let identityChar = CBMutableCharacteristic(type: TransferService.identifyRequestCharacteristic,
                                                   properties: [.write, .writeWithoutResponse], value: nil, permissions:  [.writeable])
        let requestSizeChar = CBMutableCharacteristic(type: TransferService.requestSizeCharacteristic,
                                                      properties: [.read, .indicate], value: nil, permissions:  [.readable])
        let requestChar = CBMutableCharacteristic(type: TransferService.requestCharacteristic,
                                                  properties: [.read, .indicate], value: nil, permissions:  [.readable])
        let responseSizeChar = CBMutableCharacteristic(type: TransferService.responseSizeCharacteristic,
                                                       properties: [.write, .writeWithoutResponse], value: nil, permissions: [.writeable])
        let responseChar = CBMutableCharacteristic(type: TransferService.responseCharacteristic,
                                                    properties: [.write, .writeWithoutResponse], value: nil, permissions:  [.writeable])
        let semaphoreChar = CBMutableCharacteristic(type: TransferService.semaphoreCharacteristic,
                                                    properties: [.write, .writeWithoutResponse, .read, .indicate], value: nil, permissions:  [.readable, .writeable])
        let verificationChar = CBMutableCharacteristic(type: TransferService.verificationStatusCharacteristic,
                                                       properties: [.read, .indicate], value: nil, permissions:  [.readable])
        // let dummy = CBMutableService(type: TransferService.dummySvc, primary: true)
        // let dummy2 = CBMutableService(type: TransferService.dummySvc2, primary: false)
        // TODO: Put create a CBMutableCharacteristic collection
        // maybe an array or a Dictionary of CBUUID: CBMutableCharacteristic
        transferService.characteristics = [identityChar, requestSizeChar, requestChar, responseChar, responseSizeChar, semaphoreChar, verificationChar]
        print(transferService.debugDescription)
        peripheralManager.add(transferService)
        peripheralManager.add(scanRespService)
        // peripheralManager.add(dummy)
        // peripheralManager.add(dummy2)
        // TODO: Find out how many bytes are remaining for advertising packets now.
        // peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [TransferService.serviceUUID]])
        startAdvertising()
    }

    private func startAdvertising() {
        // not setting Local name via CBAdvertisementDataLocalNameKey
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: relevantPeripherals])
    }

    func sendData(message: String) {
        guard let writeCharacteristic = readCharacteristic else {
            return
        }
        let encryptedMessage = encrypt(plainText: message)
        // writeCharacteristic
        let didSend = peripheralManager.updateValue(Data(bytes: encryptedMessage, count: encryptedMessage.count), for: writeCharacteristic, onSubscribedCentrals: nil)
        // peripheral writing data for central?
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
            let characteristicDataArray = [UInt8](aRequest.value!)
            let decryptedText = decrypt(cipherBytes: characteristicDataArray)
            os_log("Peripheral: Received %d bytes: %s", decryptedText.count, decryptedText)
            self.publishedMessages.append(Message(content: decryptedText, user: User(name: "Central", isCurrentUser: false)))
/*
            if let requestValue = aRequest.value,
               let stringFromData = String(data: requestValue, encoding: .utf8) {
               self.publishedMessages.append(Message(content: stringFromData, user: User(name: "Central", isCurrentUser: false)))
            }else {
                os_log("Found not data")
            }
 */
        }
    }
}

