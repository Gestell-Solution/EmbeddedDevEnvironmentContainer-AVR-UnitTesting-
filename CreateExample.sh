#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="Firmware"

echo "Creating ${PROJECT_NAME} structure..."

mkdir -p "${PROJECT_NAME}/src"
mkdir -p "${PROJECT_NAME}/test/unity"
cd "${PROJECT_NAME}"

# 2. Generate Source Files (src/)
cat > src/blinky.h <<'EOF'
#ifndef BLINKY_H
#define BLINKY_H

int toggle_led(int current_state);

#endif
EOF

cat > src/blinky.c <<'EOF'
#include "blinky.h"

int toggle_led(int current_state) {
    // If state is 1, return 0. If 0, return 1.
    return current_state ? 0 : 1;
}
EOF

cat > src/main.c <<'EOF'
#include "blinky.h"

// This is the main function for the AVR Microcontroller
int main(void) {
    int state = 0;
    while(1) {
        state = toggle_led(state);
    }
    return 0;
}
EOF

# 3. Generate Mock Unity Framework (test/unity/)
cat > test/unity/unity.h <<'EOF'
#ifndef UNITY_H
#define UNITY_H

void setUp(void);
void tearDown(void);
void UnityAssertEqualNumber(int expected, int actual, int line);

#define TEST_ASSERT_EQUAL(expected, actual) UnityAssertEqualNumber((expected), (actual), __LINE__)

#endif
EOF

cat > test/unity/unity.c <<'EOF'
#include "unity.h"
#include <stdio.h>

void UnityAssertEqualNumber(int expected, int actual, int line) {
    if (expected != actual) {
        printf("FAIL at line %d\n", line);
    } else {
        printf("PASS at line %d\n", line);
    }
}
EOF

# 4. Generate Unit Test (test/)
cat > test/test_blinky.c <<'EOF'
#include "unity.h"
#include "blinky.h"

// Required by Unity
void setUp(void) {}
void tearDown(void) {}

void test_toggle_led_should_return_opposite(void) {
    TEST_ASSERT_EQUAL(0, toggle_led(1));
    TEST_ASSERT_EQUAL(1, toggle_led(0));
}

// This is the main function for the unit test!
// Our container must compile this WITHOUT including src/main.c
int main(void) {
    test_toggle_led_should_return_opposite();
    return 0;
}
EOF

# 5. Create CompilingYourProject.sh inside the firmware folder
echo "Writing CompilingYourProject.sh inside ${PROJECT_NAME}..."
cat > CompilingYourProject.sh <<'EOF'
#!/bin/bash

# --- CONFIGURATION ---
URL="http://127.0.0.1:8050/run"
PROJECT_NAME=$(basename "$PWD") # Grabs the current folder name
TEMP_ZIP="project.zip"
OUTPUT_ZIP="results.zip"
CONFIG_FILE="build_config.json"

# Terminal colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
DARKGRAY='\033[1;30m'
NC='\033[0m' # No Color

echo -e "${CYAN}--- Container Engine: Advanced Build Mode ($PROJECT_NAME) [Linux Bash] ---${NC}"

# 1. Determine Configuration via JSON
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}Configuration file not found. Let's create one!${NC}"
    
    BUILD_TYPE=""
    while [[ "$BUILD_TYPE" != "c" && "$BUILD_TYPE" != "avr" ]]; do
        read -p "Is this C or AVR code? (Enter 'c' or 'avr'): " BUILD_TYPE
        BUILD_TYPE=$(echo "$BUILD_TYPE" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    done

    MCU="atmega328p"
    CPU_FREQ="16000000"
    
    if [ "$BUILD_TYPE" == "avr" ]; then
        read -p "Enter MCU (default: atmega328p): " INPUT_MCU
        if [ -n "$(echo "$INPUT_MCU" | tr -d '[:space:]')" ]; then
            MCU=$(echo "$INPUT_MCU" | tr -d '[:space:]')
        fi

        # Smart Frequency Parser
        VALID_FREQ=false
        while [ "$VALID_FREQ" = false ]; do
            read -p "Enter CPU Freq (e.g., 16M, 8MHz, 500K) [default: 16M]: " INPUT_FREQ
            if [ -z "$(echo "$INPUT_FREQ" | tr -d '[:space:]')" ]; then
                VALID_FREQ=true # Keep default 16000000
            else
                # Clean up input: remove spaces and make uppercase
                CLEAN_FREQ=$(echo "$INPUT_FREQ" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
                
                # Regex match for numbers, optional decimals, and M, K, or HZ
                if [[ "$CLEAN_FREQ" =~ ^([0-9\.]+)(M|K)?(HZ)?$ ]]; then
                    VAL="${BASH_REMATCH[1]}"
                    UNIT="${BASH_REMATCH[2]}"
                    
                    # Using awk to handle potential floating point math (like 1.5M -> 1500000)
                    CPU_FREQ=$(awk -v val="$VAL" -v unit="$UNIT" 'BEGIN {
                        if (unit == "M") val *= 1000000
                        else if (unit == "K") val *= 1000
                        printf "%d", val
                    }')
                    VALID_FREQ=true
                else
                    echo -e "${RED}Invalid format. Try '16M', '8MHz', '500K', or '16000000'.${NC}"
                fi
            fi
        done
    fi

    read -p "Enter any extra GCC flags (e.g., -O2 -Wall) or press Enter to skip: " EXTRA_FLAGS

    # Create the JSON Object dynamically
    cat <<JSON_EOF > "$CONFIG_FILE"
{
  "build_type": "$BUILD_TYPE",
  "mcu": "$MCU",
  "cpu_freq": "$CPU_FREQ",
  "extra_flags": "$EXTRA_FLAGS"
}
JSON_EOF
    echo -e "${GREEN}Saved configuration to $CONFIG_FILE.${NC}"
else
    echo -e "${DARKGRAY}Found $CONFIG_FILE. Using existing settings.${NC}"
fi

# 2. Packaging
if [ -f "$TEMP_ZIP" ]; then
    rm "$TEMP_ZIP"
fi

echo "Zipping files..."
# Exclude the configuration file, shell scripts, and powershell scripts from the zip
zip -r "$TEMP_ZIP" . -x "*.vscode*" "*.git*" "$TEMP_ZIP" "*.ps1" "*.sh" "*.out" "$OUTPUT_ZIP" "$CONFIG_FILE" > /dev/null

# 3. Shipping to the Container
echo "Action: Sending to Factory..."
HTTP_STATUS=$(curl -s -w "%{http_code}" -o "$OUTPUT_ZIP" -X POST -F "config=@$CONFIG_FILE" -F "file=@$TEMP_ZIP" "$URL")

# 4. Cleanup & Results
if [ -f "$TEMP_ZIP" ]; then
    rm "$TEMP_ZIP"
fi

if [ "$HTTP_STATUS" -eq 200 ]; then
    echo -e "${GREEN} Success! Received: $OUTPUT_ZIP${NC}"
else
    echo -e "${RED}Error $HTTP_STATUS${NC}"
    if [ -f "$OUTPUT_ZIP" ]; then
        cat "$OUTPUT_ZIP"
        echo "" # Add a newline for readability
        rm "$OUTPUT_ZIP"
    fi
fi
EOF

chmod +x CompilingYourProject.sh

echo "Project created successfully! You can now deploy it."
