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
    var deviceName: String = "ThoughtWorks India"
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
        // print(transferService.debugDescription)
        peripheralManager.add(transferService)
        // TODO: Find out how many bytes are remaining for advertising packets now.
        // peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [TransferService.serviceUUID]])
        
        // ref: https://www.dotnetperls.com/convert-string-byte-array-swift#:~:text=In%20Swift%20a%20byte%20is,we%20get%20a%20UTF8View%20collection.
        // not setting Local name via CBAdvertisementDataLocalNameKey
        // converted advt payload -> 0x1cd2e4d8359597366da26c8c8ef37700 as per https://stackoverflow.com/a/32976951
        // Didn't use CChar as it is Int8 & Byte in Swift
        let k1: [UInt8] = [0x1c, 0xd2, 0xe4, 0xd8, 0x35, 0x95, 0x97, 0x36, 0x6d, 0xa2, 0x6c,
                           0x8c, 0x8e, 0xf3, 0x77, 0x0]
        // converted scan resp payload -> 0x11fea3e7c56fb9beb9f3e3200bca6304 as per https://stackoverflow.com/a/32976951
        let k2: [UInt8] = [0x11, 0xfe, 0xa3, 0xe7, 0xc5, 0x6f, 0xb9, 0xbe, 0xb9, 0xf3, 0xe3,
                           0x20, 0x0b, 0xca, 0x63, 0x04]
        let map :[CBUUID:NSData] = [
            TransferService.serviceUUID: NSData(bytes: k1, length: k1.count),
            TransferService.scanResponseServiceUUID: NSData(bytes: k2, length: k2.count)]
        
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [TransferService.serviceUUID],
                                            // set the device local name as required
                                            // if this isn't set the Android/other devices use the Bluetooth device name iirc
                                            // ref: https://stackoverflow.com/questions/29203983/clearing-ios-ble-cache
                                               CBAdvertisementDataLocalNameKey: self.deviceName,
                                            // if the below line is uncommented, the app crashes if the datatype matches exactly the oone mentioned in code comments
                                            // stacktrace in ios-errors/Service\ Data.txt
                                            // if a string value is used, the app doesn't crash
                                            // but a StackOverflow answer mentions that it's a ReadOnly field
                                            // ref: https://stackoverflow.com/a/67028141
                                             CBAdvertisementDataServiceDataKey: map as Any
                                           ])
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
        case .poweredOff:
            os_log("toggled device localName")
            self.deviceName = "ACME International India"
            print("peripheral name changed! Peripheral can be setup again successfully!")
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

