uniffi_macros::include_scaffolding!("identity");

use aes_gcm::{
    aead::{Aead, KeyInit, OsRng, generic_array::{GenericArray, typenum}},
    Aes256Gcm, Nonce, Key // Or `Aes128Gcm`
};
use lazy_static::lazy_static;

lazy_static! {
    static ref NONCE: GenericArray<u8, typenum::UInt<typenum::UInt<typenum::UInt<typenum::UInt<typenum::UTerm, typenum::B1>, typenum::B1>, typenum::B0>, typenum::B0>> = *Nonce::from_slice(b"unique nonce");
}

static HARDCODED_AES_KEY: [u8; 32] = [213, 171, 156, 252, 142, 182, 51, 37, 130, 203, 180, 13, 127, 175, 54, 114, 32, 52, 19, 150, 181, 118, 11, 14, 78, 201, 143, 17, 240, 62, 16, 254];

fn encrypt(plain_text: String) -> Vec<u8> {
    let cipher = Aes256Gcm::new_from_slice(&HARDCODED_AES_KEY).unwrap();
    cipher.encrypt(&NONCE, plain_text.as_bytes().as_ref()).unwrap()
}

fn decrypt(cipher_bytes: Vec<u8>) -> String {
    let cipher = Aes256Gcm::new_from_slice(&HARDCODED_AES_KEY).unwrap();
    String::from_utf8(cipher.decrypt(&NONCE, cipher_bytes.as_ref()).unwrap()).unwrap()
}