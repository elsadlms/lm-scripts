# LM Scripts

Ce repo regroupe une collection de scripts pour automatiser diverses tâches, notamment le traitement des images.

## Installation

Dans un terminal, se placer dans le dossier où on souhaite installer les scripts et exécuter les commandes suivantes :

```bash
git clone git@github.com:elsadlms/lm-scripts.git
cd lm-scripts 
chmod +x *.sh  # À exécuter seulement la première fois
```

## Scripts de traitement d'images

Le dossier `./images` contient une collection de scripts bash permettant de renommer, convertir, formater et compresser des images. Les images à traiter doivent être placées dans le dossier `./input`, et les images générées seront stockées dans `./output`.

### rename

Renomme toutes les images du dossier `./input` en ajoutant un préfixe optionnel.

```bash
./rename.sh -p <prefix>
```

### format

Redimensionne toutes les images du dossier `./input` à une largeur maximale : soit la valeur passée en paramètre, soit 1920px par défaut pour les images au format paysage et 1200px par défaut pour les images au format portrait.

```bash
./format.sh -l <limit>
```

### convert

Convertit les images du dossier `./input` en un format spécifié et les sauvegarde dans le dossier `./output`. Par défaut, la conversion se fait en webp.

Formats supportés : jpg, png, webp, avif.

```bash
./convert.sh -f <format>
```

### compress

Compresse les images avec la qualité passée en paramètre (valeur entre 0 et 100). Par défaut, la qualité est de 85.

```bash
./compress.sh -q <quality>
```
