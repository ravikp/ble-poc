uniffi_macros::include_scaffolding!("identity");

use aes_gcm::{
    aead::{
        generic_array::{typenum, GenericArray},
        Aead, KeyInit,
    },
    Aes256Gcm,
    Key, // Or `Aes128Gcm`
    Nonce,
};
use hkdf::Hkdf;
use sha2::Sha256;

use rand_core::OsRng;
use x25519_dalek::{EphemeralSecret, PublicKey, StaticSecret};
use std::sync::{Arc, Mutex};

// ************************************************************************
// Below implementation is the required cryptography as per spec
// However the API can still be polished based on higher layer requirement
// ************************************************************************

static HARDCODED_SALT: [u8; 6] = [53, 48, 41, 32, 35, 36];

struct KeyPair {
    sec_key: StaticSecret,
}

impl KeyPair {
    fn new() -> Self {
        KeyPair { sec_key: StaticSecret::new(OsRng::default()) }
    }

    fn get_pub_key(self: &Arc<Self>) -> Vec<u8> {
        let pub_key = PublicKey::from(&self.sec_key);
        pub_key.to_bytes().to_vec()
    }

    fn get_shared_secret(self: &Arc<Self>, their_pub_key: Vec<u8>) -> Vec<u8> {
        let t_pub_key: [u8;32] = their_pub_key.as_slice().try_into().expect("invalidsize");
        let pub_key = &PublicKey::from(t_pub_key);
        StaticSecret::diffie_hellman(&self.sec_key, pub_key).as_bytes().to_vec()
    }
}

fn get_hkdf_key(shared_secret: Vec<u8>, info: String) -> Vec<u8> {
    let (prk, _) = Hkdf::<Sha256>::extract(Some(&HARDCODED_SALT[..]), &shared_secret);
    let hk = Hkdf::<Sha256>::from_prk(&prk).expect("PRK should be large enough");
    let mut okm = [0u8; 42];
    let info_bytes = info.as_bytes();
    hk.expand(info_bytes, &mut okm).expect("42 is a valid length for Sha256 to output");
    okm.to_vec()
}

fn aes_gcm_encrypt(key: Vec<u8>, plain_text: String) -> Vec<u8> {
    let cipher = Aes256Gcm::new_from_slice(&key[..32]).unwrap();
    cipher
        .encrypt(&NONCE, plain_text.as_bytes().as_ref())
        .unwrap()
}

fn aes_gcm_decrypt(key: Vec<u8>, cipher_bytes: Vec<u8>) -> String {
    let cipher = Aes256Gcm::new_from_slice(&key[..32]).unwrap();
    String::from_utf8(cipher.decrypt(&NONCE, cipher_bytes.as_ref()).unwrap()).unwrap()
}

#[cfg(test)]
mod tests {
    use crate::{KeyPair, get_hkdf_key, aes_gcm_encrypt, aes_gcm_decrypt};
    use std::sync::Arc;

    #[test]
    fn int_check_enc_local() {
        let key_pair1 = Arc::new(KeyPair::new());
        let pub_key = key_pair1.get_pub_key();
        dbg!(&pub_key);
        let shared_secret = key_pair1.get_shared_secret(pub_key);
        dbg!(&shared_secret);
        let hkdf_key = get_hkdf_key(shared_secret, "INJI".to_string());
        dbg!(&hkdf_key);

        let plain_text = "VerifiablePresentationRequest";
        let enc_data = aes_gcm_encrypt(hkdf_key.clone(), plain_text.to_string());
        let dec_text = aes_gcm_decrypt(hkdf_key, enc_data);

        assert_eq!(dec_text, plain_text);
    }

    #[test]
    fn int_check_enc_between_devices() {
        let key_pair_wallet = Arc::new(KeyPair::new());
        let pub_key_wallet = key_pair_wallet.get_pub_key();
        dbg!(&pub_key_wallet);

        let key_pair_verifier = Arc::new(KeyPair::new());
        let pub_key_verifier = key_pair_verifier.get_pub_key();
        dbg!(&pub_key_verifier);

        let shared_secret_wallet = key_pair_wallet.get_shared_secret(pub_key_verifier);
        dbg!(&shared_secret_wallet);

        let hkdf_key_wallet = get_hkdf_key(shared_secret_wallet, "INJI".to_string());
        dbg!(&hkdf_key_wallet);

        let shared_secret_verifier = key_pair_verifier.get_shared_secret(pub_key_wallet);
        dbg!(&shared_secret_verifier);

        let hkdf_key_verifier = get_hkdf_key(shared_secret_verifier, "INJI".to_string());
        dbg!(&hkdf_key_verifier);

        // send from Verifier to Wallet
        let plain_text = "VerifiablePresentationRequest";
        let enc_data = aes_gcm_encrypt(hkdf_key_verifier.clone(), plain_text.to_string());
        let dec_text = aes_gcm_decrypt(hkdf_key_wallet.clone(), enc_data);
        assert_eq!(dec_text, plain_text);

        // send from Wallet to Verifier
        let plain_text = "VerifiablePresentationResponse";
        let enc_data = aes_gcm_encrypt(hkdf_key_wallet.clone(), plain_text.to_string());
        let dec_text = aes_gcm_decrypt(hkdf_key_verifier, enc_data);

        assert_eq!(dec_text, plain_text);
    }
}

// ************************************************************************
// Below is the encrypt and decrypt functions needed for Android and IOS codebases
// This implementation is with hardcoded AES key used only for Demo
// ************************************************************************
use lazy_static::lazy_static;

lazy_static! {
    static ref NONCE: GenericArray<
        u8,
        typenum::UInt<
            typenum::UInt<
                typenum::UInt<typenum::UInt<typenum::UTerm, typenum::B1>, typenum::B1>,
                typenum::B0,
            >,
            typenum::B0,
        >,
    > = *Nonce::from_slice(b"unique nonce");
    static ref X25519_SECRET_KEY: Arc<Mutex<Option<EphemeralSecret>>> = Arc::new(Mutex::new(None));
}

static HARDCODED_AES_KEY: [u8; 32] = [
    213, 171, 156, 252, 142, 182, 51, 37, 130, 203, 180, 13, 127, 175, 54, 114, 32, 52, 19, 150,
    181, 118, 11, 14, 78, 201, 143, 17, 240, 62, 16, 254,
];


fn encrypt(plain_text: String) -> Vec<u8> {
    let cipher = Aes256Gcm::new_from_slice(&HARDCODED_AES_KEY).unwrap();
    cipher
        .encrypt(&NONCE, plain_text.as_bytes().as_ref())
        .unwrap()
}

fn decrypt(cipher_bytes: Vec<u8>) -> String {
    let cipher = Aes256Gcm::new_from_slice(&HARDCODED_AES_KEY).unwrap();
    String::from_utf8(cipher.decrypt(&NONCE, cipher_bytes.as_ref()).unwrap()).unwrap()
}

// ************************************************************************
// This is an attempt to use EphemeralKey Object from x25519 lib.
// This has compile time issues due to limitations from the lib
// ************************************************************************

// static X25519_SECRET_KEY: Arc<Mutex<Option<EphemeralSecret>>> = Arc::new(Mutex::new(None));

// fn get_shareable_key_details(theirs_pub: Vec<u8>) -> Vec<u8> {
//     let sec_key = EphemeralSecret::new(OsRng::default());
//     let pub_key = PublicKey::from(theirs_pub.as_slice());
//     EphemeralSecret::diffie_hellman(sec_key, &pub_key).as_bytes().to_vec()
// }

// fn setEphemeralKey() {
//     let setter_ref = X25519_SECRET_KEY.clone();
//     let mut sec_key = setter_ref.lock().unwrap();
//     *sec_key = Some(EphemeralSecret::new(OsRng::default()));
// }

// fn getPublicKey() -> Vec<u8> {
//     let setter_ref = X25519_SECRET_KEY.clone();
//     let sec_key = setter_ref.lock().unwrap();
//     let public_key = PublicKey::from((&sec_key).as_ref().unwrap());
//     public_key.to_bytes().to_vec()
// }

// fn generateSharedSecret(theirs_pub: Vec<u8>) -> Vec<u8> {
//     let pub_key: [u8; 32] = theirs_pub.try_into().expect("Cannot convert vector to pub key slice");
//     let setter_ref = X25519_SECRET_KEY.clone();
//     let sec_key = setter_ref.lock().unwrap();
//     // let unwrapped_sec_key = sec_key.unwrap();
//     EphemeralSecret::diffie_hellman(sec_key.unwrap(), &PublicKey::from(pub_key)).as_bytes().to_vec()
// }
