#!/bin/bash

# Define input/output directories
INPUT_DIR="./input"
OUTPUT_DIR="./output"

# Create output directory if it doesn't exist
[ ! -d "$OUTPUT_DIR" ] && mkdir -p "$OUTPUT_DIR"

# Supported audio extensions
EXTENSIONS=("m4a" "mp3" "wav" "WAV")

# Default bitrate if none provided
BITRATE="192k"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -b|--bitrate)
            BITRATE="$2"
            shift 2
            ;;
        *)
            echo "Unknown parameter: $1"
            exit 1
            ;;
    esac
done

echo "Using bitrate: $BITRATE"

# Process audio files
for ext in "${EXTENSIONS[@]}"; do
    for f in "$INPUT_DIR"/*."$ext"; do
        [ -f "$f" ] || continue

        filename=$(basename -- "$f")
        base="${filename%.$ext}"

        output_file="$OUTPUT_DIR/${base}.mp3"

        # Skip if input is already an mp3 with the same base name
        if [[ "$ext" == "mp3" && -f "$output_file" ]]; then
            echo "Skipping $f (output already exists)"
            continue
        fi

        echo "Converting $f → $output_file"
        ffmpeg -i "$f" -vn -ar 44100 -ac 2 -b:a "$BITRATE" "$output_file"
    done
done

echo "Conversion complete."