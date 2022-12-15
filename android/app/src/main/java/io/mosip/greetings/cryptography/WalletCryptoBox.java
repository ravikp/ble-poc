package io.mosip.greetings.cryptography;

public interface WalletCryptoBox {
    byte[] publicKey();
    SecretsTranslator buildSecretsTranslator(byte[] walletPublicKey);
}
