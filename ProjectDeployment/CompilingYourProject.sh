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

    MCU="atmega128"
    CPU_FREQ="16000000"
    
    if [ "$BUILD_TYPE" == "avr" ]; then
        read -p "Enter MCU (default: atmega128): " INPUT_MCU
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
    cat <<EOF > "$CONFIG_FILE"
{
  "build_type": "$BUILD_TYPE",
  "mcu": "$MCU",
  "cpu_freq": "$CPU_FREQ",
  "extra_flags": "$EXTRA_FLAGS"
}
EOF
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