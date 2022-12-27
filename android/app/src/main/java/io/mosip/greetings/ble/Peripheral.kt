package io.mosip.greetings.ble

import android.bluetooth.*
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.os.ParcelUuid
import android.util.Log
import io.mosip.greetings.chat.ChatManager
import io.mosip.greetings.cryptography.CipherBox
import io.mosip.greetings.cryptography.CryptoBox
import io.mosip.greetings.cryptography.CryptoBoxBuilder
import io.mosip.greetings.transfer.Assembler
import io.mosip.greetings.transfer.Message
import java.nio.charset.Charset
import java.security.SecureRandom
import java.util.*

// Sequence of actions
// Broadcasting/Advertising -> Connecting -> Indicate Central when data available to read
class Peripheral : ChatManager {
    private lateinit var cipherBox: CipherBox
    private lateinit var cryptoBox: CryptoBox
    private lateinit var updateLoadingText: (String) -> Unit
    private lateinit var advertiser: BluetoothLeAdvertiser
    private lateinit var gattServer: BluetoothGattServer
    private lateinit var onConnect: () -> Unit
    private lateinit var onMessageReceived: (String) -> Unit
    private var centralDevice: BluetoothDevice? = null
    var advertising: Boolean = false
    val assembler: Assembler = Assembler()

    companion object {
        @Volatile
        private lateinit var instance: Peripheral
        val serviceUUID: UUID = UUIDHelper.uuidFromString("AB29")
        val scanResponseUUID: UUID = UUIDHelper.uuidFromString("AB2A")
        val WRITE_MESSAGE_CHAR_UUID = UUIDHelper.uuidFromString("00002031-5026-444A-9E0E-D6F2450F3A77")
        val IDENTIFY_REQ_CHAR_UUID = UUIDHelper.uuidFromString("2033")
        val READ_MESSAGE_CHAR_UUID = UUIDHelper.uuidFromString("2032")

        fun getInstance(): Peripheral {
            synchronized(this) {
                if (!::instance.isInitialized) {
                    instance = Peripheral()
                }
                return instance
            }
        }
    }

    fun start(context: Context, onConnect: () -> Unit, updateLoadingText: (String) -> Unit) {
        val bluetoothManager:BluetoothManager =
            context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val mBluetoothAdapter = bluetoothManager.adapter
        advertiser = mBluetoothAdapter.bluetoothLeAdvertiser
        Log.i("BLE Peripheral", "Max advertisement data length: ${mBluetoothAdapter.leMaximumAdvertisingDataLength}")

        gattServer = bluetoothManager.openGattServer(context, gattServerCallback)

        val service = getService()
        val settings = advertiseSettings()
        
        cryptoBox = CryptoBoxBuilder().setSecureRandomSeed(SecureRandom()).build()
        val publicKey = cryptoBox.publicKey


        val advertisementData = createAdvertiseData(service.uuid, publicKey.copyOfRange(0,16))
        val scanResponse = createScanResponse(scanResponseUUID, publicKey.copyOfRange(16,32))

        this.onConnect = onConnect
        this.updateLoadingText = updateLoadingText

        advertiser.startAdvertising(settings, advertisementData,scanResponse, advertisingCallback)
        Log.i("BLE Peripheral", "Started advertising: $advertisementData")
    }

    fun stop() {
        advertiser.stopAdvertising(advertisingCallback)
    }

    private fun createAdvertiseData(packetId: UUID?, payload: ByteArray): AdvertiseData? {
        val parcelUuid = ParcelUuid(packetId)
        return AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addServiceUuid(parcelUuid)
            .addServiceData(parcelUuid, payload)
            .build()
    }

    private fun createScanResponse(packetId: UUID?, payload: ByteArray): AdvertiseData? {
        val parcelUuid = ParcelUuid(packetId)
        return AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addServiceData(parcelUuid, payload)
            .build()
    }

    private fun advertiseSettings(): AdvertiseSettings? {
        return AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel( AdvertiseSettings.ADVERTISE_TX_POWER_ULTRA_LOW)
            .setConnectable(true)
            .build()
    }

    private fun getService(): BluetoothGattService {
        val service = BluetoothGattService(
            serviceUUID,
            BluetoothGattService.SERVICE_TYPE_PRIMARY
        )

        val writeChar = BluetoothGattCharacteristic(
            WRITE_MESSAGE_CHAR_UUID,
            BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE or BluetoothGattCharacteristic.PROPERTY_WRITE,
            BluetoothGattCharacteristic.PERMISSION_WRITE)

        val identifyChar = BluetoothGattCharacteristic(
            IDENTIFY_REQ_CHAR_UUID,
            BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE or BluetoothGattCharacteristic.PROPERTY_WRITE,
            BluetoothGattCharacteristic.PERMISSION_WRITE)

        val readChar = BluetoothGattCharacteristic(
            READ_MESSAGE_CHAR_UUID,
            BluetoothGattCharacteristic.PROPERTY_READ or BluetoothGattCharacteristic.PROPERTY_INDICATE,
            BluetoothGattCharacteristic.PERMISSION_READ
        )

        // 2902 - GATT Descriptor UUID for Client characteristic configuration
        readChar.addDescriptor(BluetoothGattDescriptor(UUID.fromString("00002902-0000-1000-8000-00805f9b34fb"),
            BluetoothGattDescriptor.PERMISSION_READ or  BluetoothGattDescriptor.PERMISSION_WRITE))

        service.addCharacteristic(writeChar)
        service.addCharacteristic(readChar)
        service.addCharacteristic(identifyChar)

        val status = gattServer.addService(service)
        Log.i("BLE Peripheral","Added service $status" )

        return service
    }

    private val gattServerCallback: BluetoothGattServerCallback = object : BluetoothGattServerCallback(){

        override fun onMtuChanged(device: BluetoothDevice?, mtu: Int) {
            super.onMtuChanged(device, mtu)
            Log.i("BLE Peripheral", "New MTU size: $mtu. The device is $device")
        }

        override fun onDescriptorWriteRequest(
            device: BluetoothDevice?,
            requestId: Int,
            descriptor: BluetoothGattDescriptor?,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?
        ) {
            super.onDescriptorWriteRequest(
                device,
                requestId,
                descriptor,
                preparedWrite,
                responseNeeded,
                offset,
                value
            )

            Log.i("BLE Peripheral", "Got descriptor write request with value $value for ${descriptor?.uuid}")

            if(responseNeeded) {
                Log.i("BLE Peripheral", "Sending response to descriptor write")
                gattServer.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, ByteArray(0))

            }
        }
        override fun onNotificationSent(device: BluetoothDevice?, status: Int) {
            super.onNotificationSent(device, status)
            Log.i("BLE Peripheral", "Notification sent to device: $device and status: $status")
        }

        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice?,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?
        ) {
            super.onCharacteristicWriteRequest(device, requestId, characteristic, preparedWrite, responseNeeded, offset, value)
            if (value != null) {
                if (characteristic.uuid == IDENTIFY_REQ_CHAR_UUID) {
                    Log.d("BLE Peripheral", "Public Key from Central. Characteristic=" + characteristic.uuid + " value=" + value.toUByteArray())
                    cipherBox = cryptoBox.createCipherBox(value)
                }
                else {
                    assembler.push(value)
                    if(assembler.isComplete) {
                        val completeMessage = assembler.assemble()
                        Log.d("BLE Peripheral", "Are messages same:  ${completeMessage.equals(Message().message)}")
                        sendMessage("Received all chunks")
                        onMessageReceived(completeMessage)
                    }else {
                        Log.d("BLE Peripheral", "Msg from Central. Characteristic=" + characteristic.uuid)
                        sendMessage(assembler.chunkIndex.toString())
                    }
                }
            }

           if (responseNeeded) {
                val response = gattServer.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null)
                Log.i("BLE Peripheral", "Send Response : $response")
            }
        }

        override fun onCharacteristicReadRequest(
            device: BluetoothDevice?,
            requestId: Int,
            offset: Int,
            characteristic: BluetoothGattCharacteristic
        ) {
            super.onCharacteristicReadRequest(device, requestId, offset, characteristic)
            Log.d("BLE Peripheral", "onCharacteristicReadRequest requestId=$requestId offset=$offset")
            gattServer.sendResponse(
                device,
                requestId,
                BluetoothGatt.GATT_SUCCESS,
                offset,
                characteristic.value
            )
        }
        override fun onConnectionStateChange(device: BluetoothDevice?, status: Int, newState: Int) {
            super.onConnectionStateChange(device, status, newState)

            if(newState == BluetoothProfile.STATE_CONNECTED){
                Log.i("BLE Peripheral", "Device connected. $device")
                device?.let {
                    updateLoadingText("connected to ${device.name}.")
                    centralDevice = it
                    onConnect()
                }
            } else {
                centralDevice = null
                Log.i("BLE Peripheral", "Device got disconnected. $device $newState")
            }
        }

    }

    private val advertisingCallback = object: AdvertiseCallback(){
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
            super.onStartSuccess(settingsInEffect)
            advertising = true

            Log.i("BLE Peripheral", "Advertising onStartSuccess")
        }

        override fun onStartFailure(errorCode: Int) {
            advertising = false
            super.onStartFailure(errorCode)
            Log.e("BLE Peripheral", "Advertising onStartFailure: $errorCode")

        }
    }

    override fun addMessageReceiver(onMessageReceived: (String) -> Unit) {
        this.onMessageReceived = onMessageReceived
    }

    override fun sendMessage(message: String): String? {
        val output = gattServer.getService(serviceUUID).getCharacteristic(READ_MESSAGE_CHAR_UUID)

        val dataToSend = if(message == "Start") "1" else message
        output.setValue(dataToSend)

        if(centralDevice != null) {
            Log.i("BLE Peripheral", "Sent notification to device $centralDevice from ${output.uuid}. Value = ${dataToSend}")
            gattServer.notifyCharacteristicChanged(centralDevice!!, output, true)
            return null
        } else {
            return "Central is not connected."
        }
    }

    override fun name(): String = "Peripheral"
}