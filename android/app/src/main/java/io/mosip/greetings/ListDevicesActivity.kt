package io.mosip.greetings

import android.bluetooth.BluetoothDevice
import android.os.Bundle
import android.util.Log
import android.widget.ListView
import android.widget.SimpleAdapter
import androidx.appcompat.app.AppCompatActivity
import io.mosip.greetings.ble.Central
import io.mosip.greetings.ble.Device

var count =0
class ListDevicesActivity : AppCompatActivity() {
    private lateinit var listView: ListView
    //lateinit var  userCount: Int

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_device_list)
        listView = findViewById(R.id.listView)

        //TODO change the DS
        val list = ArrayList<HashMap<String, Object>>()

        //val list = io.mosip.greetings.ble.peripheralDevices as ArrayList<HashMap<String,Object>>
        Log.i("List Devices","This is before")

        val users: HashMap<BluetoothDevice, String> = intent.getSerializableExtra("devices") as HashMap<BluetoothDevice, String>
          //  intent.getSerializableExtra("devices", HashMap::class.java) as HashMap<BluetoothDevice, Object>
        Log.i("List Devices","THis is After $users")
        Log.i("List Devices","THis is before")

        for ((key, value) in users) {
            val map = HashMap<String, Object>()
            map["deviceAddress"] = key as Object
            map["deviceName"] = value as Object
            list.add(map)
        }


        Log.i("###list: ", "$list")
        val from = arrayOf("deviceAddress", "deviceName")
        val to = intArrayOf(R.id.deviceAddress, R.id.deviceName)
        val simpleAdapter = SimpleAdapter(this, list, R.layout.activity_device_list, from, to)

        count++
        Log.i("List Activity","This is called $count times")

        simpleAdapter.notifyDataSetChanged()
        listView.adapter = simpleAdapter



//        if(userCount != users.size) {
//            Log.i("List Devices","User count is called before $userCount")
//            simpleAdapter.notifyDataSetChanged()
//            userCount = users.size
//            Log.i("List Devices","User count is called after $userCount")
//        }
        listView.setOnItemClickListener { parent, _, position, _ ->

            val selectedItem: HashMap<String, Object> = parent.getItemAtPosition(position) as HashMap<String, Object>
            Log.i("List Devices", "Test : ${parent.getItemAtPosition(position)}")

            val central = Central.getInstance()
            Log.i("List Devices", "Listener is working")

            val keyByIndex = selectedItem.keys.elementAt(0) // Get key by index.
            val valueOfElement: BluetoothDevice = selectedItem.getValue(keyByIndex) as BluetoothDevice
            Log.i("selected Device", "$valueOfElement")

            central.onPeripheralSelected(valueOfElement)
        }
    }
}