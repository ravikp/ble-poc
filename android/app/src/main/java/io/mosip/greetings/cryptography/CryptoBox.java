package io.mosip.greetings.cryptography;

interface CryptoBox {
    int INITIALISATION_VECTOR_LENGTH = 12;
    byte[] getPublicKey();
    CipherBoxPackage createCipherBoxes(byte[] otherPublicKey, String selfInfo, String receipientInfo, byte[] ivBytes);
}



