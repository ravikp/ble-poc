package io.mosip.greetings.cryptography;

import android.util.Log;

import org.bouncycastle.util.encoders.Hex;

import java.security.SecureRandom;

class WalletCryptoBoxImpl implements WalletCryptoBox {
    private final CryptoBox selfCryptoBox;
    private SecureRandom secureRandom;

    WalletCryptoBoxImpl(SecureRandom random) {
        this.selfCryptoBox = new CryptoBoxBuilder().setSecureRandomSeed(random).build();
        this.secureRandom = random;
    }

    @Override
    public byte[] publicKey() {
        Log.d("CryptoBox", "Wallet publickey: " + Hex.toHexString(selfCryptoBox.getPublicKey()));
        return selfCryptoBox.getPublicKey();
    }

    @Override
    public SecretsTranslator buildSecretsTranslator(byte[] verifierPublicKey) {
        byte[] ivBytes = new byte[CryptoBox.INITIALISATION_VECTOR_LENGTH];
        secureRandom.nextBytes(ivBytes);

        CipherPackage cipherPackage = selfCryptoBox.createCipherPackage(verifierPublicKey, KeyGenerator.WALLET_INFO, KeyGenerator.VERIFIER_INFO, ivBytes);
        return new SenderTransfersOwnershipOfData(ivBytes, cipherPackage);
    }
}
