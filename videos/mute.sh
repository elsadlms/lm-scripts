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

        # Supprime la piste audio du fichier vidéo
        ffmpeg -i "$f" -c copy -an "$OUTPUT_DIR/${filename}.$ext"
    done
done

echo "Piste audio supprimée."