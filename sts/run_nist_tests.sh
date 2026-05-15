#!/bin/bash

# ==========================================
# NIST STS Automation Script
# (Aggregated 15-Test Summary Output)
# ==========================================

if [ ! -f "assess" ]; then
    echo "Error: 'assess' executable not found. Run from sts-2.1.2 directory."
    exit 1
fi

# Point exactly to the pure raw binary files we generated
IMAGES=(
    "../original_image.bin"
    "../encrypted_ECB.bin"
    "../encrypted_CBC.bin"
    "../encrypted_CFB.bin"
    "../encrypted_OFB.bin"
)

NIST_DIRS=(
    "ApproximateEntropy" "BlockFrequency" "CumulativeSums"
    "FFT" "Frequency" "LinearComplexity" "LongestRun"
    "NonOverlappingTemplate" "OverlappingTemplate"
    "RandomExcursions" "RandomExcursionsVariant" "Rank"
    "Runs" "Serial" "Universal"
)

MASTER_REPORT="../NIST_Comprehensive_Report.txt"
> "$MASTER_REPORT"

for IMG in "${IMAGES[@]}"; do
    if [ ! -f "$IMG" ]; then
        echo "Warning: File $IMG not found. Skipping..."
        continue
    fi

    echo "-----------------------------------------------------"
    echo "Testing: $IMG"

    for dir in "${NIST_DIRS[@]}"; do
        mkdir -p "experiments/AlgorithmTesting/$dir"
    done

    # Calculate single stream length safely
    FILE_SIZE=$(stat -c %s "$IMG")
    TOTAL_BITS=$((FILE_SIZE * 8))
    STREAM_LENGTH=$((TOTAL_BITS - 128))
    
    # Anti-Infinite-Loop Safeguard
    if [ "$STREAM_LENGTH" -le 0 ]; then
        echo "Error: Stream length is zero or negative. File might be empty. Skipping..."
        continue
    fi

    echo "File is $TOTAL_BITS bits. Running 1 stream of $STREAM_LENGTH bits..."

    ./assess "$STREAM_LENGTH" <<EOF > nist_debug_log.txt 2>&1
0
$IMG
1
0
1
1
EOF

    REPORT_PATH="experiments/AlgorithmTesting/finalAnalysisReport.txt"
    
    if [ -f "$REPORT_PATH" ]; then
        BASENAME=$(basename "$IMG")
        
        # Clean up the name for the report whether it's encrypted or original
        SHORT_NAME=${BASENAME#encrypted_}
        SHORT_NAME=${SHORT_NAME%.bin}
        
        echo "=== $SHORT_NAME ===" >> "$MASTER_REPORT"
        echo "--------------------------------------------------------" >> "$MASTER_REPORT"
        echo " TEST NAME                 | RESULTS" >> "$MASTER_REPORT"
        echo "--------------------------------------------------------" >> "$MASTER_REPORT"
        
        awk '
        BEGIN {
            tests[1]="Frequency"; tests[2]="BlockFrequency"; tests[3]="CumulativeSums";
            tests[4]="Runs"; tests[5]="LongestRun"; tests[6]="Rank"; tests[7]="FFT";
            tests[8]="NonOverlappingTemplate"; tests[9]="OverlappingTemplate"; tests[10]="Universal";
            tests[11]="ApproximateEntropy"; tests[12]="RandomExcursions";
            tests[13]="RandomExcursionsVariant"; tests[14]="Serial"; tests[15]="LinearComplexity";
            
            total_passed = 0; total_tests = 0;
        }
        /^[ \t]*[0-9]/ {
            test_name = $NF; prop = $(NF-1);
            if (prop ~ /[0-9]+\/[0-9]+/) {
                split(prop, frac, "/");
                passed[test_name] += frac[1]; total[test_name] += frac[2];
                total_passed += frac[1]; total_tests += frac[2];
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
        
        mkdir -p "experiments/Results_$BASENAME"
        cp -r experiments/AlgorithmTesting/* "experiments/Results_$BASENAME/"
        find experiments/AlgorithmTesting -type f -name "*.txt" -delete
    else
        echo "Error: Test failed entirely for $IMG."
        cat nist_debug_log.txt
    fi
done

rm -f nist_debug_log.txt
echo "-----------------------------------------------------"
echo "Automation Complete! Report saved at: $MASTER_REPORT"