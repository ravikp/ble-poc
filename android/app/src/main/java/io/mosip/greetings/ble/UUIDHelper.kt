package io.mosip.greetings.ble

import java.util.*
import java.util.regex.Pattern

object UUIDHelper {
    // base UUID used to build 128 bit Bluetooth UUIDs
    const val UUID_BASE = "0000XXXX-0000-1000-8000-00805f9b34fb"
    const val UUID_BASE2 = "0000XXXX-5026-444A-9E0E-D6F2450F3A77"

    // handle 16 and 128 bit UUIDs
    fun uuidFromString(uuid: String): UUID {
        var uuid = uuid
        if (uuid.length == 4) {
            uuid = UUID_BASE2.replace("XXXX", uuid)
        }
        return UUID.fromString(uuid)
    }
}