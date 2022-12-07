package io.mosip.greetings.cryptography;

import org.bouncycastle.crypto.AsymmetricCipherKeyPair;
import org.bouncycastle.crypto.AsymmetricCipherKeyPairGenerator;
import org.bouncycastle.crypto.Digest;
import org.bouncycastle.crypto.InvalidCipherTextException;
import org.bouncycastle.crypto.agreement.X25519Agreement;
import org.bouncycastle.crypto.digests.SHA256Digest;
import org.bouncycastle.crypto.engines.AESEngine;
import org.bouncycastle.crypto.generators.HKDFBytesGenerator;
import org.bouncycastle.crypto.generators.X25519KeyPairGenerator;
import org.bouncycastle.crypto.modes.GCMBlockCipher;
import org.bouncycastle.crypto.params.AEADParameters;
import org.bouncycastle.crypto.params.AsymmetricKeyParameter;
import org.bouncycastle.crypto.params.HKDFParameters;
import org.bouncycastle.crypto.params.KeyParameter;
import org.bouncycastle.crypto.params.X25519KeyGenerationParameters;
import org.bouncycastle.crypto.params.X25519PublicKeyParameters;
import org.bouncycastle.util.encoders.Hex;

import java.security.SecureRandom;

public class CryptoBoxImpl implements CryptoBox {
    private final AsymmetricCipherKeyPair keyPair;

    public CryptoBoxImpl(SecureRandom randomSeed) {
        AsymmetricCipherKeyPairGenerator kpGen = new X25519KeyPairGenerator();
        kpGen.init(new X25519KeyGenerationParameters(randomSeed));
        keyPair = kpGen.generateKeyPair();
    }

    @Override
    public byte[] getPublicKey() {
        final AsymmetricKeyParameter aPublic = keyPair.getPublic();
        final X25519PublicKeyParameters keyParameters = (X25519PublicKeyParameters) aPublic;
        return keyParameters.getEncoded();
    }

    @Override
    public CipherBox createCipherBox(byte[] otherPublicKey) {
        //Generate a weak shared key
        byte[] weakKey = generateWeakKeyBasedOnX25519(otherPublicKey);

        //Generate a strong shared key with HKDF
        byte[] strongKey = generateStrongKeyBasedOnHKDF(weakKey);

        return new CipherBoxImpl(strongKey);
    }

    private byte[] generateWeakKeyBasedOnX25519(byte[] otherPublicKey) {
        X25519Agreement keyAgreement = new X25519Agreement();
        keyAgreement.init(keyPair.getPrivate());
        byte[] weakSharedSecret = new byte[keyAgreement.getAgreementSize()];
        keyAgreement.calculateAgreement(new X25519PublicKeyParameters(otherPublicKey, 0), weakSharedSecret, 0);
        return weakSharedSecret;
    }

    private byte[] generateStrongKeyBasedOnHKDF(byte[] inputKeyMaterial) {
        Digest hash = new SHA256Digest();

        byte[] salt = Hex.decode("000102030405060708090a0b0c");
        byte[] info = Hex.decode("f0f1f2f3f4f5f6f7f8f9");
        byte[] outputKeyMaterial = new byte[inputKeyMaterial.length];

        HKDFParameters params = new HKDFParameters(inputKeyMaterial, salt, info);

        HKDFBytesGenerator hkdf = new HKDFBytesGenerator(hash);
        hkdf.init(params);
        hkdf.generateBytes(outputKeyMaterial, 0, inputKeyMaterial.length);

        return outputKeyMaterial;
    }

    private class CipherBoxImpl implements CipherBox {
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
}
