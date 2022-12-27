package io.mosip.greetings.transfer;


import android.util.Log;

public class Assembler {

    private final int totalChunks;
    private int chunkIndex = 1;

    public Assembler() {
        totalChunks = 186;
        dataReceived = new String[totalChunks];
    }

    private String[] dataReceived;

    public void push(byte[] chunk) {

        dataReceived[chunkIndex-1] = new String(chunk);
        chunkIndex++;
    }

    public int getChunkIndex() {
        return chunkIndex;
    }

    public boolean isComplete() {
        return chunkIndex == totalChunks +1 ;
    }

    public String assemble(){
        StringBuilder completeMessage = new StringBuilder();
        for(int i=0;i<totalChunks;i++){
            completeMessage.append(dataReceived[i]);
        }
        return completeMessage.toString();
    }
}

