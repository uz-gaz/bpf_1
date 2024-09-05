#!/usr/bin/env bash

usage() {
    echo "Usage: $0 --imem <string> --hfu <string>"
    exit 1
}

set -e

shopt -s extglob



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
        *)
            echo "Not valid option: $1"
            usage
            ;;
    esac
done



SCRIPT_DIR="$(dirname "$(realpath "$0")")"

SRC_DIR="$SCRIPT_DIR/../src"
TEST_FILE="$SCRIPT_DIR/../test/BPF_Data_Path_test.vhd"

COMPILE="$SCRIPT_DIR/compile-vhd.sh"
SIMULATE="$SCRIPT_DIR/simulate.sh"

bash "$COMPILE" "$SRC_DIR/BPF_constants.vhd"

for file in "$SRC_DIR"/!(BPF_constants.vhd); do
    if [ -f "$file" ]; then
        bash "$COMPILE" "$file"
    fi
done

for file in "$SRC_DIR"/fake_components/!(Inst_RAM); do
    if [ -f "$file" ]; then
        bash "$COMPILE" "$file"
    fi
done

INST_RAM="$SRC_DIR/fake_components/imem/${IMEM:-default}.vhd"
HFU_ENTITY="$SRC_DIR/hfu/${HFU:-BPF_Helper_Functions_Unit}.vhd"

bash "$COMPILE" "$INST_RAM"
bash "$COMPILE" "$HFU_ENTITY"

bash "$COMPILE" "$TEST_FILE"

bash "$SIMULATE" "BPF_Data_Path_Testbench" test.ghw


