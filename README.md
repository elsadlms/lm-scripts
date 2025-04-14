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

Le dossier `./images` contient une collection de scripts bash permettant de renommer, convertir, formater et compresser des images. Les images à traiter doivent être placées dans le dossier `./input`, et les images générées sont stockées dans `./output`.

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

## Scripts de traitement de vidéos

Le dossier `./videos` contient une collection de scripts bash permettant de compresser des vidéos. Les vidéos à traiter doivent être placées dans le dossier `./input`, et les vidéos générées sont stockées dans `./output`.

Ces scripts nécessitent l'installation de `ffmpeg`.

```bash
brew install ffmpeg
```

### compress

Compresse les vidéos du dossier `./input` et les convertit en mp4. Deux vidéos sont créées dans le dossier `./output` : `[filename].mp4` (1600px de largeur) et `[filename]_mobile.mp4` (600px de largeur). Ces valeurs peuvent être modifiées en passant en paramètre les largeurs souhaitées.

```bash
./compress.sh -w <desktop_width> <mobile_width (optional)>
```

### mute

Supprime la piste audio des vidéos du dossier `./input` et les sauvegarde dans le dossier `./output`.

```bash
./mute.sh
```

### poster

Extrait la première frame de chaque vidéo du dossier `./input` et la sauvegarde dans le dossier `./output` au format jpg.

```bash
./poster.sh
```