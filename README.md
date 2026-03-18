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

### cut

Coupe les vidéos présentes dans le dossier `./input` selon les timecodes `-start` et `-end`. Ces timecodes sont optionnels. Si `-start` n’est pas précisé, le découpage commence au début de la vidéo. Si `-end` n’est pas précisé, le découpage s’arrête à la fin de la vidéo.

```bash
./cut.sh -start <HH:MM:SS> -end <HH:MM:SS>
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

## Scripts de traitement de fichiers audio

Le dossier `./audio` contient une collection de scripts bash permettant de convertir et découper des fichiers audio. Les fichiers à traiter doivent être placés dans le dossier `./input`, et les fichiers générés sont stockés dans `./output`.

Ces scripts nécessitent l'installation de `ffmpeg`.

```bash
brew install ffmpeg
```

### convert

Convertit les fichiers audio du dossier `./input` en mp3 (formats supportés : m4a, mp3).

```bash
./convert.sh 
```

### cut

Coupe les fichiers mp3 présents dans le dossier `./input` selon les timecodes `-start` et `-end`. Ces timecodes sont optionnels. Si `-start` n'est pas précisé, le découpage commence au début du fichier. Si `-end` n'est pas précisé, le découpage s'arrête à la fin du fichier.

```bash
./cut.sh -start <HH:MM:SS> -end <HH:MM:SS>
```

## Générer un snippet de cover

### pipeline
 
Redimensionne et compresse le `.jpg` placé dans `./input`, l'uploade sur Google Cloud Storage, et génère un snippet de cover verticale.
 
Le nom du fichier (sans l'extension) est utilisé comme identifiant du projet. Le dossier de destination sur le bucket est automatiquement nommé `yymm-cover-<id>` à partir de la date courante.
 
Ce script nécessite un accès à Google Cloud Storage (`gsutil` + `gcloud`), ainsi qu'un fichier `config.sh` à créer localement à partir du fichier d'exemple fourni :
 
```bash
cp cover/config.sh.example cover/config.sh
# puis éditer config.sh avec les vraies valeurs
```
 
`config.sh` est dans le `.gitignore` et ne doit jamais être commité.
 
```bash
./cover-pipeline.sh -c <credits> -q <quality> --dry-run
```
 
#### Paramètres :
 
`-c <credits>` : texte des crédits à insérer dans le snippet (vide par défaut)
 
`-q <quality>` : qualité de compression, entre 0 et 100 (par défaut à 85)
 
`--dry-run` : affiche les commandes `gsutil` sans les exécuter
 
#### Notes :
 
- Le script demande une confirmation avant d'uploader sur GCS. `--dry-run` permet de simuler l'ensemble du pipeline sans rien envoyer.
- Si la session `gcloud` est expirée, le script lance automatiquement `gcloud auth login`.
- Les fichiers générés sont sauvegardés dans `./output` : l'image compressée (`cover.jpg`) et le snippet (`snippet-yymm-cover-<id>.txt`).