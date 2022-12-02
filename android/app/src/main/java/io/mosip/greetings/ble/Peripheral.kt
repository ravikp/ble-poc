package io.mosip.greetings.ble

import android.bluetooth.*
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.os.Parcel
import android.os.ParcelUuid
import android.util.Log
import io.mosip.greetings.chat.ChatManager
import uniffi.identity.decrypt
import uniffi.identity.encrypt
import java.util.*

// Sequence of actions
// Broadcasting/Advertising -> Connecting -> Indicate Central when data available to read
class Peripheral : ChatManager {
    private lateinit var updateLoadingText: (String) -> Unit
    private lateinit var advertiser: BluetoothLeAdvertiser
    private lateinit var gattServer: BluetoothGattServer
    private lateinit var onConnect: () -> Unit
    private lateinit var onMessageReceived: (String) -> Unit
    private var centralDevice: BluetoothDevice? = null
    var advertising: Boolean = false

    companion object {
        @Volatile
        private lateinit var instance: Peripheral
        val serviceUUID: UUID = UUIDHelper.uuidFromString("AB29")
        val scanResponseUUID: UUID = UUIDHelper.uuidFromString("AB2A")
        val WRITE_MESSAGE_CHAR_UUID = UUIDHelper.uuidFromString("2031")
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

        //max 20bytes in advertisement
        val advertisementPayload: ByteArray = (21..22).map { it.toByte() }.toByteArray()

        //max 23bytes in scan response
        val scanResponsePayload: ByteArray = (61..83).map { it.toByte() }.toByteArray()

        val advertisementData = advertiseData(service.uuid, advertisementPayload)
        val scanResponse = scanDataAdvertiseData(scanResponseUUID, scanResponsePayload)

        this.onConnect = onConnect
        this.updateLoadingText = updateLoadingText

        advertiser.startAdvertising(settings, advertisementData, advertisingCallback)
//        advertiser.startAdvertising(settings, advertisementData,scanResponse, advertisingCallback)
        Log.i("BLE Peripheral", "Started advertising: $advertisementData")
    }

    fun stop() {
        advertiser.stopAdvertising(advertisingCallback)
    }

    private fun advertiseData(packetid: UUID?, payload: ByteArray): AdvertiseData? {
        val parcelUuid = ParcelUuid(packetid)
        return AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addServiceUuid(parcelUuid)
            .addServiceData(ParcelUuid.fromString(UUIDHelper.UUID_BASE_SIG), payload)
            .build()
    }

    private fun scanDataAdvertiseData(packetid: UUID?, payload: ByteArray): AdvertiseData? {
        val parcelUuid = ParcelUuid(packetid)
        return AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addServiceUuid(parcelUuid)
            .addServiceData(parcelUuid, payload)
            .build()
    }

    private fun advertiseSettings(): AdvertiseSettings? {
        return AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_ULTRA_LOW)
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

        val status = gattServer.addService(service)
        Log.i("BLE Peripheral","Added service $status" )

        return service
    }

    private val gattServerCallback: BluetoothGattServerCallback = object : BluetoothGattServerCallback(){
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
            super.onCharacteristicWriteRequest(
                device,
                requestId,
                characteristic,
                preparedWrite,
                responseNeeded,
                offset,
                value
            )


            if(value != null) {
                val decryptedMsg = decrypt(value.toUByteArray().asList())
                Log.d(
                    "BLE Peripheral",
                    "onCharacteristicWriteRequest characteristic=" + characteristic.uuid + " value=" + decryptedMsg
                )
                onMessageReceived(decryptedMsg)
            }

            if(responseNeeded) {
                gattServer.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null)
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
        val output = gattServer
            .getService(serviceUUID)
            .getCharacteristic(READ_MESSAGE_CHAR_UUID)

        val encryptedMsg = encrypt(message)
        output.setValue(encryptedMsg.toUByteArray().toByteArray())

        if(centralDevice != null) {
            Log.i("BLE Peripheral", "Sent notification to device $centralDevice from ${output.uuid}")
            gattServer.notifyCharacteristicChanged(centralDevice!!, output, false)
            return null
        } else {
            return "Central is not connected."
        }
    }

    override fun name(): String = "Peripheral"
}