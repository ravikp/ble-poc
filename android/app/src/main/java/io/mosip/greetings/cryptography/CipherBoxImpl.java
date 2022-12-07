package io.mosip.greetings.cryptography;

import org.bouncycastle.crypto.InvalidCipherTextException;
import org.bouncycastle.crypto.engines.AESEngine;
import org.bouncycastle.crypto.modes.GCMBlockCipher;
import org.bouncycastle.crypto.params.AEADParameters;
import org.bouncycastle.crypto.params.KeyParameter;

public class CipherBoxImpl implements CipherBox {
    private final byte[] nonce;
    private KeyParameter secretKey;

    static final int NUMBER_OF_MAC_BYTES = 16; //16 Bytes of MAC Digest

    public CipherBoxImpl(byte[] secretKey) {
        this.secretKey = new KeyParameter(secretKey);
        this.nonce = new byte[16]; //16 byte zeros
    }

    @Override
    public byte[] encrypt(byte[] plainText) {
        byte[] output = process(plainText, true);
        return output;
    }

    @Override
    public byte[] decrypt(byte[] cipherText) {
        byte[] output = process(cipherText, false);
        return output;
    }

    private byte[] process(byte[] payload, boolean forEncryption) {
        GCMBlockCipher gcmBlockCipher = initialiseAESEngineWithGCM(forEncryption);
        byte[] output = new byte[gcmBlockCipher.getOutputSize(payload.length)];
        int length = gcmBlockCipher.processBytes(payload, 0, payload.length, output, 0);

        try {
            length += gcmBlockCipher.doFinal(output, length);

            if (output.length != length)
                System.out.println("encryption/decryption reported incorrect length");

        } catch (InvalidCipherTextException e) {
            e.printStackTrace();
        }
        return output;
    }

    private GCMBlockCipher initialiseAESEngineWithGCM(boolean forEncryption) {
        final AESEngine aesEngine = new AESEngine();
        GCMBlockCipher gcmBlockCipher = new GCMBlockCipher(aesEngine);
        AEADParameters aeadParameters = new AEADParameters(secretKey, NUMBER_OF_MAC_BYTES * 8, nonce);
        gcmBlockCipher.init(forEncryption, aeadParameters);
        return gcmBlockCipher;
    }
}
