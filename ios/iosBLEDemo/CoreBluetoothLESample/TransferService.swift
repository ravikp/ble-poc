/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Transfer service and characteristics UUIDs
*/

import Foundation
import CoreBluetooth

// This is technically a TransferConstants IMO
// Services contain characteristics
struct TransferService {
    /*
     Android sample UUIDs
     Service: 0000AB29-0000-1000-8000-00805f9b34fb
     Write Char: 00002031-0000-1000-8000-00805f9b34fb
     Read Char: 00002032-0000-1000-8000-00805f9b34fb
     */
	static let serviceUUID = CBUUID(string: "0000AB29-0000-1000-8000-00805f9b34fb")
    static let writeChar = CBUUID(string: "00002031-0000-1000-8000-00805f9b34fb")
    static let readChar = CBUUID(string: "00002032-0000-1000-8000-00805f9b34fb")
}
