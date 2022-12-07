package io.mosip.greetings.cryptography;

public interface CipherBox {
    byte[] encrypt(byte[] plainText);
    byte[] decrypt(byte[] cipherText);
}

