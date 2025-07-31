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

Compresse les vidéos du dossier `./input` et les convertit en mp4, en appliquant le réglage CRF spécifié (par défaut à 28 ; plus le CRF est élevé, plus la compression est forte).

```bash
./compress.sh -crf <crf>
```

### format

Redimensionne les vidéos du dossier `./input`, par défaut à 1200px et 600px. Ces valeurs peuvent être modifiées en passant en paramètre les largeurs souhaitées.

```bash
./format.sh -w <width1> <width2> ...
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

### process

Un combo de tous les scripts précédents : pour chaque vidéo du dossier `./input`, il redimensionne (par défaut à 1600px, sinon aux largeurs passées en paramètre), extrait un poster, compresse, et supprime la piste audio si le paramètre `-m` est passé.

```bash
./process.sh -m -crf <crf> -w <width1> <width2> ...
```

#### Paramètres :

`-m` : supprime l’audio (mute)

`-crf <crf>` : qualité vidéo (plus le CRF est élevé, plus la compression est forte ; par défaut à 28)

`-w <width1> <width2> ...` : une ou plusieurs largeurs cibles, en pixels (ex : `-w 1920 1280 600`)
