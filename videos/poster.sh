#!/bin/bash

# Définissez le chemin vers les dossiers input et output
INPUT_DIR="./input"
OUTPUT_DIR="./output"

# Vérifiez si le dossier output existe, sinon créez-le
[ ! -d "$OUTPUT_DIR" ] && mkdir -p "$OUTPUT_DIR"

# Liste des extensions à traiter
declare -a EXTENSIONS=("mov" "avi" "mkv" "mp4")

# Convertissez les fichiers pour chaque extension dans la liste
for ext in "${EXTENSIONS[@]}"; do
    for f in "$INPUT_DIR"/*.$ext; do
        # Vérifiez si le fichier existe pour éviter l'erreur "aucun fichier" 
        [ -f "$f" ] || continue
        
        # Extrait le nom de fichier sans l'extension
        filename=$(basename -- "$f")
        filename="${filename%.$ext}"

        # Extrait la première frame de la vidéo
        ffmpeg -i "$f" -vf "select=eq(n\,0)" -frames:v 1 -update 1 "$OUTPUT_DIR/${filename}.jpg"

        # Redimensionne et compresse l'image à un maximum de 1600 pixels
        convert "$OUTPUT_DIR/${filename}.jpg" -resize 1600x1600\> -quality 85 "$OUTPUT_DIR/${filename}.jpg"
    done
done

echo "Poster créé."
