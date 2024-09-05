#!/usr/bin/env bash

usage() {
    echo "Usage: $0 --imem <string> --tb <string> --hfu <string>"
    exit 1
}

set -e

while [[ $# -gt 0 ]]; do
    case $1 in
        --imem)
            if [[ -n "$2" && "$2" != --* ]]; then
                IMEM="$2"
                shift 2
            else
                echo "Error: --imem option must be followed by string."
                usage
            fi
            ;;
        --hfu)
            if [[ -n "$2" && "$2" != --* ]]; then
                HFU="$2"
                shift 2
            else
                echo "Error: --hfu option must be followed by string."
                usage
            fi
            ;;
        --tb)
            if [[ -n "$2" && "$2" != --* ]]; then
                TESTBENCH="$2"
                shift 2
            else
                echo "Error: --tb option must be followed by string."
                usage
            fi
            ;;
        *)
            echo "Not valid option: $1"
            usage
            ;;
    esac
done



SCRIPT_DIR="$(dirname "$(realpath "$0")")"

SRC_DIR="$SCRIPT_DIR/../src"
TEST_DIR="$SCRIPT_DIR/../test"

COMPILE="$SCRIPT_DIR/compile-vhd.sh"
SIMULATE="$SCRIPT_DIR/simulate.sh"

bash "$COMPILE" "$SRC_DIR/BPF_constants.vhd"

for file in "$SRC_DIR"/*.vhd; do
    if [ -f "$file" ] && [ ! "$file" = "$SRC_DIR/BPF_constants.vhd" ]; then
        bash "$COMPILE" "$file"
    fi
done

for file in "$SRC_DIR"/fake_components/*.vhd; do
    if [ -f "$file" ]; then
        bash "$COMPILE" "$file"
    fi
done

bash "$COMPILE" "$SRC_DIR/fake_components/bram/BRAM.vhd"
bash "$COMPILE" "$SRC_DIR/fake_components/bram/mem_components.vhd"

INST_RAM="$SRC_DIR/fake_components/imem/${IMEM:-default}.vhd"
HFU_ENTITY="$SRC_DIR/hfu/${HFU:-BPF_Helper_Functions_Unit}.vhd"
TEST_FILE="$TEST_DIR/peripheral_test/${TESTBENCH:-program_test}.vhd"

bash "$COMPILE" "$INST_RAM"
bash "$COMPILE" "$HFU_ENTITY"

bash "$COMPILE" "$TEST_FILE"
echo "$COMPILE" "$TEST_FILE"

bash "$SIMULATE" "BPF_Peripheral_Testbench" test.ghw


