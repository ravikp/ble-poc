/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class to advertise, send notifications and receive data from central looking for transfer service and characteristic.
*/

import UIKit
import CoreBluetooth
import os
import MessageKit
import Messages
import InputBarAccessoryView

class PeripheralViewController: UIViewController {
    @IBOutlet var spinner: UIActivityIndicatorView!
    @IBAction func cancelButtonTapped() {
        spinner.hidesWhenStopped=true
        spinner.stopAnimating()
        navigationController?.popToRootViewController(animated: true)
        // TODO: Perform bluetooth peripheral resource cleanups
        peripheralManager.stopAdvertising()
    }
    var peripheralManager: CBPeripheralManager!
    var readCharacteristic: CBMutableCharacteristic?
    var writeCharacteristic: CBMutableCharacteristic?
    var connectedCentral: CBCentral?
    var dataToSend = Data()

    var sendDataIndex: Int = 0

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [TransferService.serviceUUID]])
        super.viewDidLoad()
        spinner.startAnimating()
        spinner.color=UIColor.blue
//        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
//        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "peripheralchat") as! PChatViewController
//        nextViewController.title = "Chat"
//        navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Don't keep advertising going while we're not showing.
        // isConnected.text = "Disconnecting"
        // TODO: Check if the peripheralManager needs to gracefully terminate connections with the central
        peripheralManager.stopAdvertising()
        // TODO: Cleanup BLE Peripheral resources, de-allocate ChatView if required
        // TODO: Cleanup discovered BLE Peripherals
        super.viewWillDisappear(animated)
    }

    // MARK: - Helper Methods

    /*
     *  Sends the next amount of data to the connected central
     */
    static var sendingEOM = false

    private func sendData() {
		// this is sort of a nil check on it
		guard let transferCharacteristic = readCharacteristic else {
            os_log("transferCharacteristic found to be null")
			return
		}
		
        // First up, check if we're meant to be sending an EOM
        if PeripheralViewController.sendingEOM {
            // send it
            let didSend = peripheralManager.updateValue("EOM".data(using: .utf8)!, for: transferCharacteristic, onSubscribedCentrals: nil)
            // Did it send?
            if didSend {
                // It did, so mark it as sent
                PeripheralViewController.sendingEOM = false
                os_log("Sent: EOM")
            }
            // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
            return
        }
        
        // We're not sending an EOM, so we're sending data
        // Is there any left to send?
        if sendDataIndex >= dataToSend.count {
            // No data left.  Do nothing
            return
        }
        
        // There's data left, so send until the callback fails, or we're done.
        var didSend = true
        while didSend {
            
            // Work out how big it should be
            var amountToSend = dataToSend.count - sendDataIndex
            if let mtu = connectedCentral?.maximumUpdateValueLength {
                amountToSend = min(amountToSend, mtu)
            }
            
            // Copy out the data we want
            let chunk = dataToSend.subdata(in: sendDataIndex..<(sendDataIndex + amountToSend))
            
            // Send it
            didSend = peripheralManager.updateValue(chunk, for: transferCharacteristic, onSubscribedCentrals: nil)
            
            // If it didn't work, drop out and wait for the callback
            if !didSend {
                return
            }
            
            let stringFromData = String(data: chunk, encoding: .utf8)
            os_log("Sent %d bytes: %s", chunk.count, String(describing: stringFromData))
            
            // It did send, so update our index
            sendDataIndex += amountToSend
            // Was it the last one?
            if sendDataIndex >= dataToSend.count {
                // It was - send an EOM
                
                // Set this so if the send fails, we'll send it next time
                PeripheralViewController.sendingEOM = true
                
                //Send it
                let eomSent = peripheralManager.updateValue("EOM".data(using: .utf8)!,
                                                             for: transferCharacteristic, onSubscribedCentrals: nil)
                
                if eomSent {
                    // It sent; we're all done
                    PeripheralViewController.sendingEOM = false
                    os_log("Sent: EOM")
                }
                return
            }
        }
    }

    private func setupPeripheral() {
        // Start with the CBMutableCharacteristic.
        let reader = CBMutableCharacteristic(type: TransferService.readChar,
                                             properties: [.read, .indicate],
                                             value: nil,
                                             permissions: [.readable])
        let writer = CBMutableCharacteristic(type: TransferService.writeChar,
                                             properties: [.writeWithoutResponse, .write],
                                             value: nil,
                                             permissions: [.writeable])

        // Create a service from the characteristic.
        let transferService = CBMutableService(type: TransferService.serviceUUID, primary: true)
        
        // Add the characteristic to the service.
        transferService.characteristics = [reader, writer]
        
        // And add it to the peripheral manager.
        peripheralManager.add(transferService)
        
        // Save the characteristic for later.
        self.readCharacteristic = reader
        self.writeCharacteristic = writer
        // reader.setValue(Any?, forKey: <#T##String#>)
    }
}

extension PeripheralViewController: CBPeripheralManagerDelegate {
    // implementations of the CBPeripheralManagerDelegate methods

    /*
     *  Required protocol method.  A full app should take care of all the possible states,
     *  but we're just waiting for to know when the CBPeripheralManager is ready
     *
     *  Starting from iOS 13.0, if the state is CBManagerStateUnauthorized, you
     *  are also required to check for the authorization state of the peripheral to ensure that
     *  your app is allowed to use bluetooth
     */
    internal func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        // advertisingSwitch.isEnabled = peripheral.state == .poweredOn
        
        switch peripheral.state {
        case .poweredOn:
            // ... so start working with the peripheral
            os_log("CBManager is powered on")
            setupPeripheral()
        case .poweredOff:
            os_log("CBManager is not powered on")
            // In a real app, you'd deal with all the states accordingly
            return
        case .resetting:
            os_log("CBManager is resetting")
            // In a real app, you'd deal with all the states accordingly
            // TODO: When this happens & what should be shown in UI here??
            return
        case .unauthorized:
            // TODO: Show some error?
            // In a real app, you'd deal with all the states accordingly
            if #available(iOS 13.0, *) {
                switch peripheral.authorization {
                case .denied:
                    os_log("You are not authorized to use Bluetooth")
                case .restricted:
                    os_log("Bluetooth is restricted")
                default:
                    os_log("Unexpected authorization")
                }
            } else {
                // Fallback on earlier versions
            }
            return
        case .unknown:
            os_log("CBManager state is unknown")
            // In a real app, you'd deal with all the states accordingly
            return
        case .unsupported:
            os_log("Bluetooth is not supported on this device")
            
            // In a real app, you'd deal with all the states accordingly
            return
        @unknown default:
            os_log("A previously unknown peripheral manager state occurred")
            // In a real app, you'd deal with yet unknown cases that might occur in the future
            return
        }
    }

    /*
     *  Catch when someone subscribes to our characteristic, then start sending them data
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        // isConnected.text = "Peripheral is connected to Central"
        os_log("Central subscribed to characteristic")
        
        // Get the data
        // let rustEncryptedData = getName(str: textView.text)
        // dataToSend = rustEncryptedData.data(using: .utf8)!
        
        // Reset the index
        sendDataIndex = 0
        
        // save central
        connectedCentral = central
        // Start sending
        sendData()
        
    }
    
    /*
     *  Recognize when the central unsubscribes
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        // TODO: change the isConnected text
        os_log("Central unsubscribed from characteristic")
        connectedCentral = nil
    }
    
    /*
     *  This callback comes in when the PeripheralManager is ready to send the next chunk of data.
     *  This is to ensure that packets will arrive in the order they are sent
     */
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // Start sending again
        sendData()
    }
    
    /*
     * This callback comes in when the PeripheralManager received write to characteristics
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for aRequest in requests {
            guard let requestValue = aRequest.value,
                let stringFromData = String(data: requestValue, encoding: .utf8) else {
                    continue
            }
            // TODO: Push data to the chatview
            os_log("Received write request of %d bytes: %s", requestValue.count, stringFromData)
            // self.textView.text = stringFromData
        }
    }
}

func getName(str: String) -> String {
    /*
    let private_key: [UInt8] = [176, 248, 152, 2, 121, 212, 223, 159, 56, 59, 253, 110, 153, 11, 69, 197, 252, 186, 28, 79, 190, 247, 108, 39, 185, 20, 29, 255, 80, 185, 121, 131, 252, 109, 239, 156, 33, 22, 23, 4, 81, 188, 242, 194, 118, 63, 169, 22, 150, 209, 33, 73, 23, 89, 145, 242, 38, 179, 77, 219, 226, 50, 225, 167];
    return jwtsign(privateKey: private_key, claims: str)
     */
    return str
}
