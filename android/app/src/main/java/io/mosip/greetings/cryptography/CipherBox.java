package io.mosip.greetings.cryptography;

interface CipherBox {
    byte[] encrypt(byte[] plainText);
    byte[] decrypt(byte[] cipherText);
}

