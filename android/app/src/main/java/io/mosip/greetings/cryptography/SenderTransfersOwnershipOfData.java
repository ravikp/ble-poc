package io.mosip.greetings.cryptography;

/*
vk: verifier key
wk: wallet key

The sender transfers the ownership of the data, so the sender should use the receivers key to encrypt
wallet sending data to verifier | w->v: wallet encrypts with vk and verifier decrypts with vk
verifier sending data to wallet | v->w: verifier encrypts with wk and wallet decrypts with wk
 */
class SenderTransfersOwnershipOfData implements SecretsTranslator {
    private byte[] initVector;
    private CipherBox senderCryptoBox;
    private CipherBox receiverCryptoBox;

    public SenderTransfersOwnershipOfData(byte[] initVector, CipherBoxPackage cipherBoxPackage) {
        this.initVector = initVector;
        this.senderCryptoBox = cipherBoxPackage.getSelf();
        this.receiverCryptoBox = cipherBoxPackage.getOther();
    }

    @Override
    public byte[] initializationVector() {
        return initVector;
    }

    @Override
    public byte[] encryptToSend(byte[] plainText) {
        byte[] encrypt = receiverCryptoBox.encrypt(plainText);
        return encrypt;
    }

    @Override
    public byte[] decryptUponReceive(byte[] cipherText) {
        byte[] plainText = senderCryptoBox.decrypt(cipherText);
        return plainText;
    }
}
