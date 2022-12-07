package io.mosip.greetings.cryptography;

import java.security.SecureRandom;

public class CryptoBoxBuilder {

    private SecureRandom secureRandomSeed;
    public void setSecureRandomSeed(SecureRandom secureRandomSeed) {
        this.secureRandomSeed = secureRandomSeed;
    }

    public CryptoBox build(){
        if(secureRandomSeed == null)
            throw new RuntimeException("Cannot create cryptobox without secure random seed");

        return new CryptoBoxImpl(secureRandomSeed);
    }
}
