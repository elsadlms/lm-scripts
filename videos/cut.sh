#!/bin/bash

# Default directories
INPUT_DIR="./input"
OUTPUT_DIR="./output"

# Check args
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -start) START_TIME="$2"; shift ;;
        -end) END_TIME="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Create output directory if it doesn't exist
[ ! -d "$OUTPUT_DIR" ] && mkdir -p "$OUTPUT_DIR"

# File extensions to process
EXTENSIONS=("mov" "avi" "mkv" "mp4" "MP4")

# Convert videos for each extension
for ext in "${EXTENSIONS[@]}"; do
    for f in "$INPUT_DIR"/*.$ext; do
        [ -f "$f" ] || continue

        filename=$(basename -- "$f")
        filename_no_ext="${filename%.$ext}"

        # Build ffmpeg options dynamically
        FF_OPTS=()
        [ -n "$START_TIME" ] && FF_OPTS+=("-ss" "$START_TIME")
        [ -n "$END_TIME" ] && FF_OPTS+=("-to" "$END_TIME")

        # Run ffmpeg with re-encoding for accurate cuts
        ffmpeg -hide_banner -y "${FF_OPTS[@]}" -i "$f" \
            -c:v libx264 -crf 18 -preset veryfast -c:a aac -b:a 192k \
            "$OUTPUT_DIR/${filename_no_ext}.mp4"
    done
done

# Print what was done
if [[ -n "$START_TIME" && -n "$END_TIME" ]]; then
    echo "Video cut from $START_TIME to $END_TIME completed (accurate)."
elif [[ -n "$START_TIME" ]]; then
    echo "Video cut from $START_TIME to end completed (accurate)."
elif [[ -n "$END_TIME" ]]; then
    echo "Video cut from beginning to $END_TIME completed (accurate)."
else
    echo "Full video re-encoded (no start/end provided)."
fi
