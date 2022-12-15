package io.mosip.greetings.cryptography;

public interface SecretsTranslator {
    byte[] initializationVector();
    byte[] encryptToSend(byte[] plainText);
    byte[] decryptUponReceive(byte[] cipherText);
}
