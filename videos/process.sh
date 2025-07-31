#!/bin/bash

INPUT_DIR="./input"
OUTPUT_DIR="./output"
TEMP_DIR="./temp"

[ ! -d "$OUTPUT_DIR" ] && mkdir -p "$OUTPUT_DIR"
[ ! -d "$TEMP_DIR" ] && mkdir -p "$TEMP_DIR"

EXTENSIONS=("mov" "avi" "mkv" "mp4")

MUTE=false
CRF=28
PRESET="slow"
WIDTHS=()

# Default width if none provided
DEFAULT_WIDTH=1600

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -m) MUTE=true ;;
        -crf) CRF="$2"; shift ;;
        -w) shift; while [[ "$1" =~ ^[0-9]+$ ]]; do WIDTHS+=("$1"); shift; done; set -- "$@" ;; 
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# If no widths were provided, set to default
if [ "${#WIDTHS[@]}" -eq 0 ]; then
    WIDTHS=("$DEFAULT_WIDTH")
fi

for ext in "${EXTENSIONS[@]}"; do
    for f in "$INPUT_DIR"/*."$ext"; do
        [ -f "$f" ] || continue

        filename=$(basename -- "$f")
        filename="${filename%.$ext}"

        # Get width of original video
        orig_width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$f")

        for width in "${WIDTHS[@]}"; do
            if [ "$orig_width" -gt "$width" ]; then
                echo "Resizing $f to ${width}px..."
                ffmpeg -i "$f" -vf "scale=${width}:-2" -c:a copy "$TEMP_DIR/${filename}_${width}px.mp4"
            else
                echo "Copying $f without resizing (original width ≤ ${width}px)..."
                cp "$f" "$TEMP_DIR/${filename}_${width}px.mp4"
            fi

            # Extract poster from resized version (first frame)
            echo "Creating poster for ${filename}_${width}px..."
            ffmpeg -i "$TEMP_DIR/${filename}_${width}px.mp4" -vf "select=eq(n\,0)" -frames:v 1 -update 1 "$OUTPUT_DIR/${filename}_${width}px.jpg"
            convert "$OUTPUT_DIR/${filename}_${width}px.jpg" -resize "${width}" -quality 85 "$OUTPUT_DIR/${filename}_${width}px.jpg"

            # Apply mute if needed
            if [ "$MUTE" = true ]; then
                echo "Muting audio for ${filename}_${width}px..."
                ffmpeg -i "$TEMP_DIR/${filename}_${width}px.mp4" -c copy -an "$TEMP_DIR/${filename}_${width}px_muted.mp4"
                mv "$TEMP_DIR/${filename}_${width}px_muted.mp4" "$TEMP_DIR/${filename}_${width}px.mp4"
            fi

            # Apply compression
            echo "Compressing ${filename}_${width}px..."
            ffmpeg -i "$TEMP_DIR/${filename}_${width}px.mp4" -vcodec libx264 -crf "$CRF" -preset "$PRESET" -acodec aac -b:a 128k "$OUTPUT_DIR/${filename}_${width}px.mp4"
        done
    done
done

rm -rf "$TEMP_DIR"
echo "All processing complete."
