import os
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad
from Crypto.PublicKey import RSA
from Crypto.Signature import pkcs1_15
from Crypto.Hash import SHA1

# ==========================================
# TASK 1: Image Encryption
# ==========================================
print("--- TASK 1: AES Encryption ---")

input_image = 'portal_image.bmp'

# 1. Generate a 128-bit (16-byte) encryption key
aes_key = os.urandom(16) 
print(f"Generated AES-128 Key: {aes_key.hex()}")

# Read the image
with open(input_image, 'rb') as f:
    image_data = f.read()

# Separate the BMP header (first 54 bytes) and the pixel data
header = image_data[:54]
body = image_data[54:]

# Pad the body to be a multiple of AES block size (16 bytes)
padded_body = pad(body, AES.block_size)

# Define a function to encrypt and save the image
def encrypt_and_save(mode_name, mode_flag, iv=None):
    output_filename = f'encrypted_{mode_name}.bmp'
    
    if mode_name == 'ECB':
        cipher = AES.new(aes_key, mode_flag)
    else:
        cipher = AES.new(aes_key, mode_flag, iv)
        
    ciphertext_body = cipher.encrypt(padded_body)
    
    # Reattach the unencrypted header to the encrypted body
    with open(output_filename, 'wb') as f:
        f.write(header + ciphertext_body)
    print(f"Successfully created {output_filename}")

# Generate IVs for modes that require them
iv_cbc = os.urandom(16)
iv_cfb = os.urandom(16)
iv_ofb = os.urandom(16)

# Encrypt using the 4 required modes
encrypt_and_save('ECB', AES.MODE_ECB)
encrypt_and_save('CBC', AES.MODE_CBC, iv_cbc)
encrypt_and_save('CFB', AES.MODE_CFB, iv_cfb)
encrypt_and_save('OFB', AES.MODE_OFB, iv_ofb)

# ==========================================
# TASK 2: RSA Signature and Verification
# ==========================================
print("\n--- TASK 2: RSA Signature ---")

# 1. Generate RSA 2048-bit key pair
rsa_key = RSA.generate(2048)
private_key = rsa_key
public_key = rsa_key.publickey()
print("RSA 2048-bit keys generated.")

# 2. Create a SHA1 hash for the CBC encrypted image
with open('encrypted_CBC.bmp', 'rb') as f:
    cbc_image_data = f.read()

hash_obj = SHA1.new(cbc_image_data)
print(f"SHA1 Hash of CBC image: {hash_obj.hexdigest()}")

# 3. Create an RSA signature for the hash using the private key
signature = pkcs1_15.new(private_key).sign(hash_obj)
print(f"Signature generated (first 16 bytes): {signature[:16].hex()}...")

# 4. Verify the signature using the public key
print("\nVerifying Signature...")
try:
    pkcs1_15.new(public_key).verify(hash_obj, signature)
    print("Verification Result: True (Signature is valid)")
except (ValueError, TypeError):
    print("Verification Result: False (Signature is invalid)")