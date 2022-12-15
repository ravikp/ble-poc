package io.mosip.greetings.cryptography;

public class CipherBoxPackage {
    private CipherBox self;
    private CipherBox other;

    public CipherBoxPackage(CipherBox self, CipherBox other) {
        this.self = self;
        this.other = other;
    }

    public CipherBox getSelf() {
        return self;
    }

    public CipherBox getOther() {
        return other;
    }
}
