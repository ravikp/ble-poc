package io.mosip.greetings.cryptography;

public interface CryptoBox {
    byte[] getPublicKey();
    CipherBox createCipherBox(byte[] otherPublicKey);
}

