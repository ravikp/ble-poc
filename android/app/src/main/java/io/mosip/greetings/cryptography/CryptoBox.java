package io.mosip.greetings.cryptography;

import java.security.SecureRandom;

public interface CryptoBox {
    byte[] getPublicKey();
    CipherBox createCipherBox(byte[] otherPublicKey);
}

