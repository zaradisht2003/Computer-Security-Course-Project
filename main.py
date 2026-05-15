import os
import numpy as np
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad
from Crypto.PublicKey import RSA
from Crypto.Signature import pkcs1_15
from Crypto.Hash import SHA1
import matplotlib.pyplot as plt
from PIL import Image

# ==========================================
# TASK 1: Image Encryption
# ==========================================
print("--- TASK 1: AES Encryption ---")

input_image = 'portal_image.bmp'

# Read the raw binary file directly
try:
    with open(input_image, 'rb') as f:
        raw_data = f.read()
except Exception as e:
    print(f"Error opening source image: {e}")
    exit()

# Standard BMP headers are 54 bytes. 
HEADER_SIZE = 54
header = raw_data[:HEADER_SIZE]
body = raw_data[HEADER_SIZE:]

total_body_bytes = len(body)

# --- NEW: Save the raw original body as a .bin file for NIST ---
# We strip the header so NIST only tests the actual pixel data payload
with open('original_image.bin', 'wb') as f:
    f.write(body)
print("Successfully created original_image.bin for NIST testing.")

# ... (The rest of your Python encryption code continues below) ...

# Load the image using PIL to safely handle any underlying compression
try:
    img = Image.open(input_image).convert('RGB')
except Exception as e:
    print(f"Error opening source image: {e}")
    exit()

width, height = img.size
# Get the raw, uncompressed RGB pixel bytes (1200 * 1600 * 3)
body = img.tobytes()
total_pixel_bytes = len(body)

# 1. Generate a 128-bit (16-byte) encryption key
aes_key = os.urandom(16) 
print(f"Generated AES-128 Key: {aes_key.hex()}")

# Pad the body to be a multiple of AES block size (16 bytes)
padded_body = pad(body, AES.block_size)

# Define a function to encrypt and save the image properly
# Define a function to encrypt and save both the raw bytes and the image
def encrypt_and_save(mode_name, mode_flag, iv=None):
    output_bmp = f'encrypted_{mode_name}.bmp'
    output_bin = f'encrypted_{mode_name}.bin'
    
    if mode_name == 'ECB':
        cipher = AES.new(aes_key, mode_flag)
    else:
        cipher = AES.new(aes_key, mode_flag, iv)
        
    ciphertext_body = cipher.encrypt(padded_body)
    
    # --- FIX: Save pure raw ciphertext for NIST STS ---
    # This bypasses the BMP header and row padding, preventing the NIST freeze
    with open(output_bin, 'wb') as f:
        f.write(ciphertext_body)
    
    # --- Reconstruct the image for Task 3 plotting ---
    # Truncate any extra padding blocks so it matches the exact pixel dimensions
    encrypted_pixel_bytes = ciphertext_body[:total_pixel_bytes]
    
    # Pillow handles writing the completely valid BMP header for plotting
    enc_img = Image.frombytes('RGB', (width, height), encrypted_pixel_bytes)
    enc_img.save(output_bmp)
    print(f"Successfully created {output_bmp} (Plotting) and {output_bin} (NIST)")

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

# ==========================================
# TASK 3: Image Comparison Plotting
# ==========================================
print("\n--- TASK 3: Plotting Images ---")

# List of files to plot along with their titles
images_to_plot = [
    (input_image, 'Original'),
    ('encrypted_ECB.bmp', 'AES ECB'),
    ('encrypted_CBC.bmp', 'AES CBC'),
    ('encrypted_CFB.bmp', 'AES CFB'),
    ('encrypted_OFB.bmp', 'AES OFB')
]

# Create a figure with 1 row and 5 columns
fig, axes = plt.subplots(1, 5, figsize=(20, 5))
fig.suptitle('AES Encryption Modes Comparison', fontsize=16)

# Loop through the files and axes to display each image safely via Pillow
for ax, (filename, title) in zip(axes, images_to_plot):
    try:
        img_to_show = Image.open(filename)
        ax.imshow(img_to_show)
        ax.set_title(title)
        ax.axis('off')  # Hide the axes ticks
    except Exception as e:
        ax.set_title(f"{title}\n(Error)")
        ax.axis('off')
        print(f"Error loading {filename} for plotting: {e}")

# Adjust layout to prevent overlap and display the plot
plt.tight_layout()
plt.show()