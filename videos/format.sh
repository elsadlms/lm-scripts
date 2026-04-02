#!/bin/bash
# Define input/output directories
INPUT_DIR="./input"
OUTPUT_DIR="./output"
TEMP_DIR="./temp"
# Create output/temp directories if they don't exist
[ ! -d "$OUTPUT_DIR" ] && mkdir -p "$OUTPUT_DIR"
[ ! -d "$TEMP_DIR" ] && mkdir -p "$TEMP_DIR"
# Supported extensions
EXTENSIONS=("mov" "avi" "mkv" "mp4")
# Default widths if none provided
WIDTHS=(1200 600)
# Track failures
FAILED=0
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

        # If HEVC, transcode to h264 first to normalize rotation/dimensions
        codec=$(ffprobe -v error -select_streams v:0 \
          -show_entries stream=codec_name \
          -of csv=p=0 "$f" | tr -d '[:space:],')

        if [[ "$codec" == "hevc" ]]; then
            echo "HEVC détecté pour $f — transcodage en h264 pour normaliser les dimensions..."
            temp_file="$TEMP_DIR/${filename}_temp.mp4"
            ffmpeg -i "$f" -c:v libx264 -c:a copy "$temp_file"
            if [ $? -ne 0 ] || [ ! -f "$temp_file" ]; then
                echo "ERREUR : Échec du transcodage de $f — fichier ignoré."
                FAILED=1
                continue
            fi
            probe_file="$temp_file"
        else
            probe_file="$f"
        fi

        # Get original video width
        orig_width=$(ffprobe \
          -probesize 200M \
          -analyzeduration 200M \
          -select_streams v:0 \
          -show_entries stream=width \
          -of csv=p=0 \
          -v error \
          "$probe_file" | tr -d '[:space:],')

        if [[ -z "$orig_width" || ! "$orig_width" =~ ^[0-9]+$ ]]; then
            echo "ERREUR : Impossible de lire la largeur de $f — fichier ignoré (corrompu ou illisible)."
            FAILED=1
            # Clean up temp file if it exists
            [ -f "$temp_file" ] && rm "$temp_file"
            continue
        fi

        for width in "${WIDTHS[@]}"; do
            output_file="$OUTPUT_DIR/${filename}_${width}px.mp4"
            # Use temp file as input if it was transcoded, otherwise original
            input_file="$probe_file"
            if [ "$orig_width" -gt "$width" ]; then
                echo "Redimensionnement de $f à ${width}px..."
                ffmpeg -i "$input_file" -vf "scale=${width}:-2" -c:a copy "$output_file"
            else
                echo "Copie de $f sans redimensionnement (largeur ≤ ${width}px)..."
                ffmpeg -i "$input_file" -c:v copy -c:a copy "$output_file"
            fi
        done

        # Clean up temp file
        [ -f "$temp_file" ] && rm "$temp_file"
        temp_file=""
    done
done

if [ "$FAILED" -eq 1 ]; then
    echo "Échec : un ou plusieurs fichiers n'ont pas pu être traités."
    exit 1
else
    echo "Redimensionnement terminé."
fi