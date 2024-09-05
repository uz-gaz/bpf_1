#!/usr/bin/env bash

if [ $# -ne 2 ]; then
    echo "Usage: '$0' <ENTITY> <WAVE_FILE>"
    exit 1
fi

TARGET_ENTITY="$1"
TARGET_WAVE="$2"

case "$TARGET_WAVE" in
    *.vcd)
        FORMAT="vcd"
        ;;
    *.ghw)
        FORMAT="wave"
        ;;
    *)
        echo "Invalid wave format: '$TARGET_WAVE'"
        echo "Possible file extensions: .vcd .ghw"
        exit 1
esac

BIN_DIR="./bin"
if [ ! -d "$BIN_DIR" ]; then
    echo "'$BIN_DIR' directory does not exists. Aborting..."
    exit 1
fi

WAVE_DIR="./waves"

if [ ! -d "$WAVE_DIR" ]; then
    echo "'$WAVE_DIR' directory does not exist. Creating it..."
    mkdir "$WAVE_DIR"
    if [ $? -eq 0 ]; then
        echo "'$WAVE_DIR' directory created succesfully."
    else
        echo "'$WAVE_DIR' directory could not be created. Aborting..."
        exit 1
    fi
fi

set -e

cd "$BIN_DIR"
ghdl -e --std=08 -fsynopsys -fexplicit "$TARGET_ENTITY"
ghdl -r --std=08 "$TARGET_ENTITY" --"$FORMAT"=../"$WAVE_DIR"/"$TARGET_WAVE"
