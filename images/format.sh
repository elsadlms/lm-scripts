#!/bin/bash

INPUT_FOLDER="./input"

# Initialiser la largeur max
declare -i LIMIT

# Récupérer les options
while getopts "l:" opt; do
  case $opt in
    l) LIMIT=$OPTARG ;;
    *) echo "Usage : $0 -l <limit>"; exit 1 ;;
  esac
done

# Vérifier si le dossier input existe
if [ ! -d "$INPUT_FOLDER" ]; then
    echo "Le dossier $INPUT_FOLDER n'existe pas."
    exit 1
fi

# Boucler sur chaque image dans le dossier input
for f in "$INPUT_FOLDER"/*; do
    # Vérifier si le fichier existe pour éviter l'erreur "aucun fichier"
    [ -f "$f" ] || continue

    # Récupérer les dimensions de l'image
    dimensions=$(identify -format "%wx%h" "$f")
    width=$(echo $dimensions | cut -dx -f1)
    height=$(echo $dimensions | cut -dx -f2)

    # Déterminer si l'image est en portrait ou paysage
    if [ "$width" -gt "$height" ]; then
        # Paysage: redimensionner à 1920px de large max (ou la limite fournie)
        max_width=${LIMIT:-1920}
        echo "Redimensionnement de l'image paysage $f à ${max_width}px de largeur..."
        magick "$f" -resize "$max_width"x "$f"
    else
        # Portrait: redimensionner à 1200px de large max (ou la limite fournie)
        max_width=${LIMIT:-1200}
        echo "Redimensionnement de l'image portrait $f à ${max_width}px de largeur..."
        magick "$f" -resize "$max_width" "$f"
    fi
done

echo "Redimensionnement terminé."