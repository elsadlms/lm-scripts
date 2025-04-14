#!/bin/bash

# Définissez le chemin vers les dossiers input et output
INPUT_DIR="./input"
OUTPUT_DIR="./output"

# Vérifiez si le dossier output existe, sinon créez-le
[ ! -d "$OUTPUT_DIR" ] && mkdir -p "$OUTPUT_DIR"

# Liste des extensions à traiter
declare -a EXTENSIONS=("mov" "avi" "mkv" "mp4")

# Default width values
DESKTOP_WIDTH=1600
MOBILE_WIDTH=600

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -w) DESKTOP_WIDTH="$2"; MOBILE_WIDTH="${3:-$MOBILE_WIDTH}"; shift 2 ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Convertissez les fichiers pour chaque extension dans la liste
for ext in "${EXTENSIONS[@]}"; do
    for f in "$INPUT_DIR"/*.$ext; do
        # Vérifiez si le fichier existe pour éviter l'erreur "aucun fichier" 
        [ -f "$f" ] || continue
        
        # Extrait le nom de fichier sans l'extension
        filename=$(basename -- "$f")
        filename="${filename%.$ext}"

        # Get the width of the video
        width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$f")

        # Determine the scale parameter based on the width
        if [ "$width" -gt "$DESKTOP_WIDTH" ]; then
            echo "Conversion de $f avec redimensionnement..."
            ffmpeg -i "$f" -vf "scale=${DESKTOP_WIDTH}:-2" "$OUTPUT_DIR/${filename}.mp4"
        else
            echo "Conversion de $f sans redimensionnement..."
            ffmpeg -i "$f" "$OUTPUT_DIR/${filename}.mp4"
        fi

        if [ "$width" -gt "$MOBILE_WIDTH" ]; then
            echo "Conversion de $f pour mobile avec redimensionnement..."
            ffmpeg -i "$f" -vf "scale=${MOBILE_WIDTH}:-2" "$OUTPUT_DIR/${filename}_mobile.mp4"
        else
            echo "Conversion de $f pour mobile sans redimensionnement..."
            ffmpeg -i "$f" "$OUTPUT_DIR/${filename}_mobile.mp4"
        fi
    done
done

echo "Conversion terminée."