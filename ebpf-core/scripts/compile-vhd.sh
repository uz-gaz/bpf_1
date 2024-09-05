#!/usr/bin/env bash

if [ $# -eq 0 ]; then
    echo "Usage: '$0' <SRC...>"
    exit 1
fi

BIN_DIR="./bin"

if [ ! -d "$BIN_DIR" ]; then
    echo "'$BIN_DIR' directory does not exist. Creating it..."
    mkdir "$BIN_DIR"
    if [ $? -eq 0 ]; then
        echo "'$BIN_DIR' directory created succesfully."
    else
        echo "'$BIN_DIR' directory could not be created. Aborting..."
        exit 1
    fi
fi

ghdl -a --std=08 -fsynopsys -fexplicit --workdir="$BIN_DIR" "$@"
