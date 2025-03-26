#!/bin/zsh

INPUT_FOLDER="./input"
OUTPUT_FOLDER="./output"

ALLOWED_INPUT=("jpg" "jpeg" "png" "webp" "avif")

# Initialiser la largeur max
declare -i QUALITY

# Récupérer les options
while getopts "c:" opt; do
  case $opt in
    q) QUALITY=$OPTARG ;;
    *) echo "Usage : $0 -q <quality>"; exit 1 ;;
  esac
done

# Créer le dossier de sortie s'il n'existe pas
mkdir -p "$OUTPUT_FOLDER"

for image in "$INPUT_FOLDER"/*; do
  filename=$(basename "$image")
  extension="${filename##*.}"

  # Vérifier si l'extension fait partie des formats autorisés
  if [[ " ${ALLOWED_INPUT[@]} " =~ " ${extension} " ]]; then
    # Convertir l'image
    magick "$image" -quality ${QUALITY:-85} "$OUTPUT_FOLDER/$filename"
    echo "Image compressée et sauvegardée : $image -> $OUTPUT_FOLDER/$filename"
  else
    echo "Type de fichier non supporté : $filename"
    continue
  fi
done

echo "Compression terminée."
