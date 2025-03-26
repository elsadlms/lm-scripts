#!/bin/zsh

INPUT_FOLDER="./input"
OUTPUT_FOLDER="./output"

ALLOWED_INPUT=("jpg" "jpeg" "png" "webp" "avif")
ALLOWED_OUTPUT=("jpg" "png" "webp" "avif")

OUTPUT_FORMAT="webp"

# Récupérer les options
while getopts "f:" opt; do
  case $opt in
    f) 
      OUTPUT_FORMAT=$OPTARG
      # Vérifier si le format de sortie fait partie des formats autorisés
      if [[ ! " ${ALLOWED_OUTPUT[@]} " =~ " ${OUTPUT_FORMAT} " ]]; then
        echo "Format de sortie non supporté : $OUTPUT_FORMAT"
        echo "Formats supportés : ${ALLOWED_OUTPUT[*]}"
        exit 1
      fi
      ;;
    *) 
      echo "Usage : $0 -f <format>"; 
      echo "Formats supportés : ${ALLOWED_OUTPUT[*]}";
      exit 1 
      ;;
  esac
done

# Créer le dossier de sortie s'il n'existe pas
mkdir -p "$OUTPUT_FOLDER"

for image in "$INPUT_FOLDER"/*; do
  filename=$(basename "$image")
  filename_noext="${filename%.*}"
  extension="${filename##*.}"

  # Vérifier si l'extension fait partie des formats autorisés
  if [[ " ${ALLOWED_INPUT[@]} " =~ " ${extension} " ]]; then
    # Vérifier si le format de sortie est le même que l'extension
    if [[ "$OUTPUT_FORMAT" == "$extension" ]]; then
      echo "Image déjà au format $OUTPUT_FORMAT : $image"
      continue
    fi
    # Convertir l'image
    magick "$image" -quality 85 "$OUTPUT_FOLDER/${filename_noext}.${OUTPUT_FORMAT}"
    echo "Image convertie : $image -> $OUTPUT_FOLDER/${filename_noext}.${OUTPUT_FORMAT}"
  else
    echo "Type de fichier non supporté : $filename"
    continue
  fi
done

echo "Conversion terminée."
