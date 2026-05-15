#!/bin/bash

# ==========================================
# NIST STS Automation Script 
# (Aggregated 15-Test Summary Output)
# ==========================================

if [ ! -f "assess" ]; then
    echo "Error: 'assess' executable not found. Run from sts-2.1.2 directory."
    exit 1
fi

IMAGES=(
    "../encrypted_ECB.bmp"
    "../encrypted_CBC.bmp"
    "../encrypted_CFB.bmp"
    "../encrypted_OFB.bmp"
)

# The 15 subdirectories NIST absolutely requires to not crash
NIST_DIRS=(
    "ApproximateEntropy" "BlockFrequency" "CumulativeSums"
    "FFT" "Frequency" "LinearComplexity" "LongestRun"
    "NonOverlappingTemplate" "OverlappingTemplate"
    "RandomExcursions" "RandomExcursionsVariant" "Rank"
    "Runs" "Serial" "Universal"
)

MASTER_REPORT="../NIST_Comprehensive_Report.txt"
> "$MASTER_REPORT" # Clear the master report at the start

for IMG in "${IMAGES[@]}"; do
    if [ ! -f "$IMG" ]; then
        echo "Warning: File $IMG not found. Skipping..."
        continue
    fi

    echo "-----------------------------------------------------"
    echo "Testing: $IMG"

    # 1. GUARANTEE DIRECTORIES EXIST
    for dir in "${NIST_DIRS[@]}"; do
        mkdir -p "experiments/AlgorithmTesting/$dir"
    done

    # 2. CALCULATE BITS AND ADD SAFETY BUFFER
    FILE_SIZE=$(stat -c %s "$IMG")
    TOTAL_BITS=$((FILE_SIZE * 8))
    STREAM_LENGTH=$((TOTAL_BITS - 128)) 
    
    echo "File is $TOTAL_BITS bits. Running 1 stream of $STREAM_LENGTH bits..."

    # 3. RUN NIST ASSESS
    ./assess "$STREAM_LENGTH" <<EOF > nist_debug_log.txt 2>&1
0
$IMG
1
0
1
1
EOF

    # 4. GRAB AND SUMMARIZE THE NATIVE REPORT
    REPORT_PATH="experiments/AlgorithmTesting/finalAnalysisReport.txt"
    
    if [ -f "$REPORT_PATH" ]; then
        BASENAME=$(basename "$IMG")
        SHORT_NAME=${BASENAME#encrypted_}
        SHORT_NAME=${SHORT_NAME%.bmp}
        
        echo "=== $SHORT_NAME ===" >> "$MASTER_REPORT"
        echo "--------------------------------------------------------" >> "$MASTER_REPORT"
        echo " TEST NAME                 | RESULTS" >> "$MASTER_REPORT"
        echo "--------------------------------------------------------" >> "$MASTER_REPORT"
        
        # Use awk to aggregate the 188 lines into exactly 15 test categories
        awk '
        BEGIN {
            tests[1]="Frequency"; tests[2]="BlockFrequency"; tests[3]="CumulativeSums";
            tests[4]="Runs"; tests[5]="LongestRun"; tests[6]="Rank"; tests[7]="FFT";
            tests[8]="NonOverlappingTemplate"; tests[9]="OverlappingTemplate"; tests[10]="Universal";
            tests[11]="ApproximateEntropy"; tests[12]="RandomExcursions";
            tests[13]="RandomExcursionsVariant"; tests[14]="Serial"; tests[15]="LinearComplexity";
            
            total_passed = 0;
            total_tests = 0;
        }
        # Match data lines (starts with spaces followed by numbers)
        /^[ \t]*[0-9]/ {
            test_name = $NF;
            prop = $(NF-1);
            
            if (prop ~ /[0-9]+\/[0-9]+/) {
                split(prop, frac, "/");
                passed[test_name] += frac[1];
                total[test_name] += frac[2];
                
                total_passed += frac[1];
                total_tests += frac[2];
            }
        }
        END {
            for(i=1; i<=15; i++) {
                t = tests[i];
                if (total[t] > 0) {
                    pct = (passed[t] / total[t]) * 100;
                    printf " %-25s | Passed %3d / %3d (%6.2f%%)\n", t, passed[t], total[t], pct;
                } else {
                    printf " %-25s | ------ SKIPPED ------\n", t;
                }
            }
            printf "--------------------------------------------------------\n";
            if (total_tests > 0) {
                total_pct = (total_passed / total_tests) * 100;
                printf " TOTAL OVERALL SCORE       | Passed %3d / %3d (%6.2f%%)\n", total_passed, total_tests, total_pct;
            }
        }' "$REPORT_PATH" >> "$MASTER_REPORT"
        
        echo -e "\n\n" >> "$MASTER_REPORT"
        echo "Test completed successfully!"
        
        # 5. BACKUP AND CLEANUP
        mkdir -p "experiments/Results_$BASENAME"
        cp -r experiments/AlgorithmTesting/* "experiments/Results_$BASENAME/"
        
        # Safe cleanup: Delete text files, keep folders
        find experiments/AlgorithmTesting -type f -name "*.txt" -delete
    else
        echo "Error: Test failed entirely for $IMG."
        echo "--- NIST CRASH LOG ---"
        cat nist_debug_log.txt
        echo "----------------------"
    fi

done

# Clean up debug log
rm -f nist_debug_log.txt

echo "-----------------------------------------------------"
echo "Automation Complete!"
echo "Your full report is saved at: $MASTER_REPORT"