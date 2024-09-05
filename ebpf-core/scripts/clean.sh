#!/usr/bin/env bash

BIN_DIR="./bin"

if [ -d "$BIN_DIR" ]; then
    rm -f "$BIN_DIR"/*.o "$BIN_DIR"/*.cf "$BIN_DIR"/*.exe

    if [ -z "$(ls -A "$BIN_DIR")" ]; then
        rmdir "$BIN_DIR"
    fi
fi

WAVE_DIR="./waves"

if [ -d "$WAVE_DIR" ]; then
    rm -f "$WAVE_DIR"/*.ghw "$WAVE_DIR"/*.vcd

    if [ -z "$(ls -A "$WAVE_DIR")" ]; then
        rmdir "$WAVE_DIR"
    fi
fi