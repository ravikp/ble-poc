package io.mosip.greetings.cryptography;

interface CipherBox {
    void printSecretKey(String identifier);
    byte[] encrypt(byte[] plainText);
    byte[] decrypt(byte[] cipherText);
}

