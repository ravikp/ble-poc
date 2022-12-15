package io.mosip.greetings.cryptography;

import java.security.SecureRandom;

class VerifierCryptoBoxImpl implements VerifierCryptoBox {
    private CryptoBox selfCryptoBox;

    VerifierCryptoBoxImpl(SecureRandom random) {
        this.selfCryptoBox = new CryptoBoxBuilder().setSecureRandomSeed(random).build();
    }

    @Override
    public byte[] publicKey() {
        return selfCryptoBox.getPublicKey();
    }

    @Override
    public SecretsTranslator buildCommunicator(byte[] initVector, byte[] walletPublicKey) {
        CipherBoxPackage cipherBoxPackage = selfCryptoBox.createCipherBoxes(walletPublicKey, KeyGenerator.VERIFIER_INFO, KeyGenerator.WALLET_INFO, initVector);
        return new SenderTransfersOwnershipOfData(initVector, cipherBoxPackage);
    }
}
