package io.mosip.greetings.transfer

import android.util.Log
import kotlin.math.ceil

class Chunker(private val data: UByteArray) {
    private val mtuSize = 500
    private val seqNumberReservedByteSize = 2
    private val mtuReservedByteSize = 2
    private val effectiveChunkSize = mtuSize - seqNumberReservedByteSize - mtuReservedByteSize
    private var chunksReadCounter: Int = 0
    private val totalChunks: Double = ceil((data.size / effectiveChunkSize).toDouble()) // -> 185
    private val lastChunkByteCount = data.size % effectiveChunkSize

    init {
        Log.d("Chunker", "Data size:  ${data.size}")
        Log.d("Chunker", "Total number of chunks: $totalChunks")
    }

    fun next(): UByteArray {
        val fromIndex = chunksReadCounter * effectiveChunkSize
        if (lastChunkByteCount > 0 && chunksReadCounter == (totalChunks).toInt()) {
            chunksReadCounter++
            return data.copyOfRange(fromIndex, fromIndex + lastChunkByteCount)
        }
        val toIndex = (chunksReadCounter + 1) * effectiveChunkSize
        chunksReadCounter++
        return data.copyOfRange(fromIndex, toIndex)
    }


    fun isComplete(index: Int): Boolean {
        Log.i("BLE Central", "Index: $index")
        if(lastChunkByteCount > 0)
            return index == (totalChunks+2).toInt()
        return index == (totalChunks +1).toInt() // because we have to send that last chunk and then it is complete
    }

    @OptIn(ExperimentalUnsignedTypes::class)
    fun getChunkOf(index: Int): UByteArray {
        val fromIndex = (index-1) * effectiveChunkSize

        return if (lastChunkByteCount > 0 && index == (totalChunks+1).toInt())
            data.copyOfRange(fromIndex, fromIndex + lastChunkByteCount)
        else {
            data.copyOfRange(fromIndex, (index) * effectiveChunkSize)
        }
    }

    fun getChunkReadCounter(): Int = chunksReadCounter

}
