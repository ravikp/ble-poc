package io.mosip.greetings.cryptography;

import org.bouncycastle.crypto.AsymmetricCipherKeyPair;
import org.bouncycastle.crypto.AsymmetricCipherKeyPairGenerator;
import org.bouncycastle.crypto.Digest;
import org.bouncycastle.crypto.agreement.X25519Agreement;
import org.bouncycastle.crypto.digests.SHA256Digest;
import org.bouncycastle.crypto.generators.HKDFBytesGenerator;
import org.bouncycastle.crypto.generators.X25519KeyPairGenerator;
import org.bouncycastle.crypto.params.AsymmetricKeyParameter;
import org.bouncycastle.crypto.params.HKDFParameters;
import org.bouncycastle.crypto.params.X25519KeyGenerationParameters;
import org.bouncycastle.crypto.params.X25519PublicKeyParameters;
import org.bouncycastle.util.encoders.Hex;

import java.security.SecureRandom;

public class CryptoBoxImpl implements CryptoBox {
    private final AsymmetricCipherKeyPair keyPair;

    public CryptoBoxImpl() {
        AsymmetricCipherKeyPairGenerator kpGen = new X25519KeyPairGenerator();
        kpGen.init(new X25519KeyGenerationParameters(new SecureRandom()));
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
}
