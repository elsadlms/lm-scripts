#!/bin/bash

INPUT_FOLDER="./input"

# Initialiser le préfixe
prefix=""

# Récupérer les options
while getopts "p:" opt; do
  case $opt in
    p) prefix="$OPTARG" ;;
    *) echo "Usage : $0 -p <prefix>" >&2; exit 1 ;;
  esac
done

# Initialiser le compteur
counter=1

for file in "$INPUT_FOLDER"/*; do
  # Vérifier si le fichier existe pour éviter l'erreur "aucun fichier"
  [ -f "$file" ] || continue

  # Récupérer l'extension du fichier
  extension="${file##*.}"

  # Créer le nouveau nom avec un padding de zéros
  new_name=$(printf "%s%02d.%s" "$prefix" "$counter" "$extension")

  # Construire le chemin complet pour le nouveau nom
  new_path="$INPUT_FOLDER/$new_name"

  # Renommer le fichier sur place
  mv "$file" "$new_path"
  echo "Renommé : $file -> $new_path"

  # Incrémenter le compteur
  ((counter++))
done

echo "Renommage terminé."