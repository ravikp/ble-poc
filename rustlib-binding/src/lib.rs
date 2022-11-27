pub mod androidjni;

uniffi_macros::include_scaffolding!("identity");
use std::{ffi::c_int};
use std::ptr;

use rand::{thread_rng, Rng};
use lazy_static::lazy_static;

static HARDCODED_AES_KEY: [u8; libsodium_sys::crypto_aead_aes256gcm_KEYBYTES as usize] = [213, 171, 156, 252, 142, 182, 51, 37, 130, 203, 180, 13, 127, 175, 54, 114, 32, 52, 19, 150, 181, 118, 11, 14, 78, 201, 143, 17, 240, 62, 16, 254];
static additional_data: &str = "";

lazy_static! {
    static ref NONCE: [u8; libsodium_sys::crypto_aead_aes256gcm_NPUBBYTES as usize] = thread_rng().gen();
}

fn crypto_init() {
    unsafe {
        let init_resp: c_int = libsodium_sys::sodium_init();
        println!("Libsodium init resp: {}", init_resp);
    }
}

fn encrypt(plainText: String) -> Vec<u8> {
    unsafe {
        let is_alg_available = libsodium_sys::crypto_aead_aes256gcm_is_available();
        if is_alg_available == 0 {
            return vec![];
        }
    };
    // let mut enc_key = [0; libsodium_sys::crypto_aead_aes256gcm_KEYBYTES as usize];
    // let key_ptr = enc_key.as_mut_ptr();

    // unsafe {
    //     libsodium_sys::crypto_aead_aes256gcm_keygen(key_ptr);
    //     println!("Generated aes key bytes: {:?}", enc_key);
    // };

    let key_ptr = HARDCODED_AES_KEY.as_ptr();

    let mut cipher_text: Vec<u8> = Vec::new();
    cipher_text.resize_with(
        plainText.len() + libsodium_sys::crypto_aead_aes256gcm_ABYTES as usize,
        Default::default,
    );
    let cipher_text_ptr = cipher_text.as_mut_ptr();
    let mut cipher_text_len: u64 = 0;
    

    unsafe {
        let isEncrypted = libsodium_sys::crypto_aead_aes256gcm_encrypt(
            cipher_text_ptr,
            &mut cipher_text_len,
            plainText.as_ptr(),
            plainText.len() as u64,
            additional_data.as_ptr(),
            additional_data.len() as u64,
            ptr::null(),
            NONCE.as_ptr(),
            key_ptr
        );
        println!("Is encrypted: {}", isEncrypted);
    }

    println!("Generated cipher text: {:?}", cipher_text);
    println!("Generated cipher text len: {}", cipher_text_len);

    return cipher_text;
}

fn decrypt(cipherBytes: Vec<u8>) -> String {
    let mut plain_text: Vec<u8> = Vec::new();
    plain_text.resize_with(
        cipherBytes.len(),
        Default::default,
    );
    let plain_text_ptr = plain_text.as_mut_ptr();
    let mut plain_text_len: u64 = 0;

    unsafe {
        let isDecrypted = libsodium_sys::crypto_aead_aes256gcm_decrypt(plain_text_ptr, &mut plain_text_len, ptr::null_mut(), cipherBytes.as_ptr(), cipherBytes.len() as u64, additional_data.as_ptr(), additional_data.len() as u64, NONCE.as_ptr(), HARDCODED_AES_KEY.as_ptr());
        println!("Is decrypted: {}", isDecrypted);
    }

    println!("Decrypted cipher text: {:?}", String::from_utf8_lossy(&plain_text).to_string());
    println!("Decrypted cipher text len: {}", plain_text_len);

    return String::from_utf8_lossy(&plain_text).to_string()
}