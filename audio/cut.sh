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

# Only mp3 files
EXTENSIONS=("mp3" "MP3")

# Process each audio file
for ext in "${EXTENSIONS[@]}"; do
    for f in "$INPUT_DIR"/*.$ext; do
        [ -f "$f" ] || continue

        filename=$(basename -- "$f")
        filename_no_ext="${filename%.$ext}"

        # Build ffmpeg options for time-based cut
        FF_OPTS=()
        [ -n "$START_TIME" ] && FF_OPTS+=("-ss" "$START_TIME")
        [ -n "$END_TIME" ] && FF_OPTS+=("-to" "$END_TIME")

        output_file="$OUTPUT_DIR/${filename_no_ext}_cut.mp3"

        echo "Cutting $filename → $output_file"

        ffmpeg -hide_banner -y "${FF_OPTS[@]}" -i "$f" \
            -c:a libmp3lame -b:a 192k \
            "$output_file"
    done
done

# Summary
if [[ -n "$START_TIME" && -n "$END_TIME" ]]; then
    echo "Audio cut from $START_TIME to $END_TIME completed."
elif [[ -n "$START_TIME" ]]; then
    echo "Audio cut from $START_TIME to end completed."
elif [[ -n "$END_TIME" ]]; then
    echo "Audio cut from beginning to $END_TIME completed."
else
    echo "Full audio re-encoded (no start/end provided)."
fi
