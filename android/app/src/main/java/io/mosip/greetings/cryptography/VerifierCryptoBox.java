package io.mosip.greetings.cryptography;

public interface VerifierCryptoBox {
    byte[] publicKey();
    SecretsTranslator buildSecretsTranslator(byte[] initializationVector, byte[] walletPublicKey);
}
