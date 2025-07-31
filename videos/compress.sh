#!/bin/bash

# Paths to input and output directories
INPUT_DIR="./input"
OUTPUT_DIR="./output"

# Create output directory if it doesn't exist
[ ! -d "$OUTPUT_DIR" ] && mkdir -p "$OUTPUT_DIR"

# Default compression settings
CRF=28          # Lower = better quality, larger file. 23–28 is a good range
PRESET="slow"   # Options: ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -crf) CRF="$2"; shift ;;
        -preset) PRESET="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Compress each .mp4 video in input directory
for f in "$INPUT_DIR"/*.mp4; do
    [ -f "$f" ] || continue

    filename=$(basename -- "$f")
    filename="${filename%.mp4}"

    echo "Compressing $f with CRF=$CRF and preset=$PRESET..."
    ffmpeg -i "$f" -vcodec libx264 -crf "$CRF" -preset "$PRESET" -acodec aac -b:a 128k "$OUTPUT_DIR/${filename}.mp4"
done

echo "Compression completed."