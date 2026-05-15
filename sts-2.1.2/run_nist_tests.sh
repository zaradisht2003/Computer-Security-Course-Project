#!/bin/bash

# ==========================================
# NIST STS Automation Script (With Scoring)
# ==========================================

if [ ! -f "assess" ]; then
    echo "Error: 'assess' executable not found. Run from sts-2.1.2 directory."
    exit 1
fi

IMAGES=(
    "../portal_image.bmp"
    "../encrypted_ECB.bmp"
    "../encrypted_CBC.bmp"
    "../encrypted_CFB.bmp"
    "../encrypted_OFB.bmp"
)

MASTER_REPORT="../NIST_Comprehensive_Report.txt"
echo "=====================================================" > "$MASTER_REPORT"
echo "        NIST STATISTICAL TEST SUITE RESULTS          " >> "$MASTER_REPORT"
echo "=====================================================" >> "$MASTER_REPORT"

for IMG in "${IMAGES[@]}"; do
    if [ ! -f "$IMG" ]; then
        echo "Warning: File $IMG not found. Skipping..."
        continue
    fi

    echo "-----------------------------------------------------"
    echo "Testing: $IMG"

    # Calculate exact file size in bits
    FILE_SIZE=$(stat -c %s "$IMG")
    TOTAL_BITS=$((FILE_SIZE * 8))
    
    # NIST needs at least 10 bitstreams to calculate final P-values.
    STREAM_LENGTH=$((TOTAL_BITS / 10))
    echo "Total Bits: $TOTAL_BITS. Running 10 streams of $STREAM_LENGTH bits."

    # Run NIST Assess
    ./assess "$STREAM_LENGTH" <<EOF > /dev/null 2>&1
0
$IMG
1
0
10
1
EOF

    REPORT_PATH="experiments/AlgorithmTesting/finalAnalysisReport.txt"

    if [ -f "$REPORT_PATH" ]; then
        
        # --- NEW SCORING LOGIC ---
        PASSED=0
        TOTAL=0
        
        # Extract every fraction (e.g., 9/10, 2/2) from the report
        for frac in $(grep -o -E '[0-9]+/[0-9]+' "$REPORT_PATH"); do
            p=$(echo "$frac" | cut -d'/' -f1) # Numerator
            t=$(echo "$frac" | cut -d'/' -f2) # Denominator
            PASSED=$((PASSED + p))
            TOTAL=$((TOTAL + t))
        done
        
        # Calculate percentage using awk
        if [ "$TOTAL" -gt 0 ]; then
            SCORE_PERCENT=$(awk "BEGIN {printf \"%.2f\", ($PASSED/$TOTAL)*100}")
        else
            SCORE_PERCENT="0.00"
        fi
        # -------------------------

        echo "Test completed! Total Score: $PASSED / $TOTAL ($SCORE_PERCENT%)"
        
        echo -e "\n\n=====================================================" >> "$MASTER_REPORT"
        echo " RESULTS FOR: $IMG" >> "$MASTER_REPORT"
        echo " TOTAL SCORE: $PASSED / $TOTAL ($SCORE_PERCENT%)" >> "$MASTER_REPORT"
        echo "=====================================================" >> "$MASTER_REPORT"
        cat "$REPORT_PATH" >> "$MASTER_REPORT"
        
        # Copy the results to a new folder
        BASENAME=$(basename "$IMG")
        mkdir -p "experiments/Results_$BASENAME"
        cp -r experiments/AlgorithmTesting/* "experiments/Results_$BASENAME/"
        
        # Clean up the report file for the next loop
        rm "$REPORT_PATH"
    else
        echo "Error: Test failed for $IMG. Report was not generated."
    fi

done

echo "-----------------------------------------------------"
echo "Automation Complete!"
echo "Your full report is saved at: $MASTER_REPORT"