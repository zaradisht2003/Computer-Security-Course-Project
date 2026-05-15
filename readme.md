How to Run the Project
Prerequisites
Before running the project, ensure you have Python 3 and the necessary C compilers installed on your Linux machine, and that you have installed the required cryptographic library:

Bash
# Install required system tools and Python library
sudo apt update
sudo apt install build-essential python3 python3-pip bc -y
pip3 install pycryptodome --break-system-packages
Step 1: Run Image Encryption and RSA Signature (Tasks 1 & 2)
From the root of the repository, execute the Python script. This will generate the encrypted images and verify the RSA signature.

Bash
python3 crypto_project.py
(You should see four new encrypted_*.bmp files appear in your directory, and a console message confirming the RSA signature is valid).

Step 2: Compile the NIST Statistical Test Suite
Before running the randomness tests, you must compile the NIST C-code into an executable.

Bash
# Navigate to the NIST suite directory
cd sts-2.1.2

# Compile the suite
make
Step 3: Run the Randomness Evaluation (Task 3)
With the encrypted images generated and the suite compiled, you can now run the automated testing script.

Ensure you are still inside the sts-2.1.2 directory, grant execution permissions to the script, and run it:

Bash
# Grant execution permissions
chmod +x run_nist_tests.sh

# Execute the automated test suite
./run_nist_tests.sh
Once the script finishes (it takes a few minutes to process the millions of bits), it will automatically generate your final results file: NIST_Comprehensive_Report.txt located in the root directory.