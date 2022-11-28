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

// use rand_core::OsRng;
// use x25519_dalek::{EphemeralSecret, PublicKey};
// use std::sync::{Arc, Mutex};

// static X25519_SECRET_KEY: Arc<Mutex<Option<EphemeralSecret>>> = Arc::new(Mutex::new(None));

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
//     let sec = sec_key.as_ref().unwrap();
//     (*sec).diffie_hellman(&PublicKey::from(pub_key)).as_bytes().to_vec()
// }