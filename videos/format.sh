#!/bin/bash

# Define input/output directories
INPUT_DIR="./input"
OUTPUT_DIR="./output"

# Create output directory if it doesn't exist
[ ! -d "$OUTPUT_DIR" ] && mkdir -p "$OUTPUT_DIR"

# Supported extensions
EXTENSIONS=("mov" "avi" "mkv" "mp4")

# Default widths if none provided
WIDTHS=(1200 600)

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -w)
            shift
            WIDTHS=()
            while [[ "$1" =~ ^[0-9]+$ ]]; do
                WIDTHS+=("$1")
                shift
            done
            set -- "$@"  # Re-insert non-numeric params into $@
            ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Process videos
for ext in "${EXTENSIONS[@]}"; do
    for f in "$INPUT_DIR"/*."$ext"; do
        [ -f "$f" ] || continue

        filename=$(basename -- "$f")
        filename="${filename%.$ext}"

        # Get original video width
        orig_width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$f")

        for width in "${WIDTHS[@]}"; do
            output_file="$OUTPUT_DIR/${filename}_${width}px.mp4"

            if [ "$orig_width" -gt "$width" ]; then
                echo "Resizing $f to width ${width}px..."
                ffmpeg -i "$f" -vf "scale=${width}:-2" -c:a copy "$output_file"
            else
                echo "Copying $f without resizing (width ≤ ${width}px)..."
                ffmpeg -i "$f" -c:v copy -c:a copy "$output_file"
            fi
        done
    done
done

echo "Redimensionnement terminé."
