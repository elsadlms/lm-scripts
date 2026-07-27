#!/bin/bash
# =============================================================================
# pipeline-batch.sh
# Batch version of pipeline.sh: processes every image in ./input at once.
#
# Usage:
#   ./pipeline-batch.sh [-q quality] [--dry-run]
#
# Examples:
#   ./pipeline-batch.sh
#   ./pipeline-batch.sh -q 80
#   ./pipeline-batch.sh --dry-run
#
# Reads images from: ./input/<name>.jpg (all jpg/jpeg files)
# Credits:           ./input/<name>.txt (same basename as the image, optional)
# Project ID:        derived from each jpg filename (without extension)
# Outputs:           ./output/cover-<name>.jpg  +  ./output/snippet-<folder>.txt
#
# Requirements:
#   - ImageMagick (magick, identify)
#   - gsutil + gcloud (Google Cloud SDK)
# =============================================================================

set -e

# ── Colours for output ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log()    { echo -e "${BLUE}▶${NC} $1"; }
ok()     { echo -e "${GREEN}✔${NC} $1"; }
warn()   { echo -e "${YELLOW}⚠${NC} $1"; }
error()  { echo -e "${RED}✖${NC} $1"; exit 1; }
header() { echo -e "\n${BOLD}$1${NC}"; }

# ── Load config ───────────────────────────────────────────────────────────────
CONFIG_FILE="$(dirname "$0")/config.sh"
[ ! -f "$CONFIG_FILE" ] && error "Fichier config.sh introuvable. Copie config.sh.example et renseigne les valeurs."
source "$CONFIG_FILE"

# ── Parse arguments ───────────────────────────────────────────────────────────
QUALITY=85
DRY_RUN=false

ARGS=()
for arg in "$@"; do
  [ "$arg" = "--dry-run" ] && DRY_RUN=true || ARGS+=("$arg")
done
set -- "${ARGS[@]}"

while getopts "q:" opt; do
  case $opt in
    q) QUALITY="$OPTARG" ;;
    *) echo "Usage: $0 [-q quality] [--dry-run]"; exit 1 ;;
  esac
done

# ── Validate inputs ───────────────────────────────────────────────────────────
header "🔍 Validating inputs"

INPUT_FOLDER="./input"
[ ! -d "$INPUT_FOLDER" ] && error "Folder $INPUT_FOLDER not found. Please create it and place your JPGs inside."

FILES=()
while IFS= read -r line; do
  FILES+=("$line")
done < <(find "$INPUT_FOLDER" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) | sort)
[ "${#FILES[@]}" -eq 0 ] && error "No JPG files found in $INPUT_FOLDER"

ok "Found ${#FILES[@]} image(s) in $INPUT_FOLDER"
$DRY_RUN && warn "Mode:       DRY RUN — gcloud commands will be printed but not executed"

YYMM=$(date +"%y%m")

# ── Build per-image plan ──────────────────────────────────────────────────────
header "📋 Building batch plan"

PROJECT_IDS=()
FOLDER_NAMES=()
COVER_URLS=()
CREDITS_LIST=()

for FILE in "${FILES[@]}"; do
  FILENAME=$(basename "$FILE")
  PROJECT_ID="${FILENAME%.*}"
  FOLDER_NAME="${YYMM}-cover-${PROJECT_ID}"
  COVER_URL="${ASSETS_BASE_URL}/${FOLDER_NAME}/cover.jpg"

  CREDITS_FILE="${INPUT_FOLDER}/${PROJECT_ID}.txt"
  if [ -f "$CREDITS_FILE" ]; then
    CREDITS=$(cat "$CREDITS_FILE")
  else
    CREDITS=""
    warn "No credits file for ${BOLD}${PROJECT_ID}${NC} (expected ${CREDITS_FILE}) — snippet will have empty credits"
  fi

  PROJECT_IDS+=("$PROJECT_ID")
  FOLDER_NAMES+=("$FOLDER_NAME")
  COVER_URLS+=("$COVER_URL")
  CREDITS_LIST+=("$CREDITS")

  echo ""
  ok "File:       $FILE"
  ok "Project ID: $PROJECT_ID"
  ok "Folder:     $FOLDER_NAME"
  ok "URL:        $COVER_URL"
  ok "Credits:    ${CREDITS:-<empty>}"
done

# ── Check gcloud authentication ───────────────────────────────────────────────
header "🔐 Checking GCloud authentication"

if ! gcloud auth print-access-token &>/dev/null; then
  warn "You are not logged in to GCloud."
  echo -e "  Launching ${BOLD}gcloud auth login${NC}..."
  gcloud auth login
  if ! gcloud auth print-access-token &>/dev/null; then
    error "GCloud authentication failed. Please run 'gcloud auth login' manually and retry."
  fi
fi
ok "Authenticated with GCloud"

# ── Show upload plan + confirm ────────────────────────────────────────────────
header "☁️  GCloud upload plan"
echo ""
echo -e "  For each of the ${#FILES[@]} image(s), scoped to its own dated subfolder (no full-bucket listing):"
for FOLDER_NAME in "${FOLDER_NAMES[@]}"; do
  echo -e "    ${BOLD}1.${NC} gsutil -m -h \"Cache-Control:public, max-age=60\" rsync -crpj txt <workspace>/${FOLDER_NAME}/ ${BUCKET}/${FOLDER_NAME}/"
  echo -e "    ${BOLD}2.${NC} gsutil -m acl -r ch -u allUsers:R ${BUCKET}/${FOLDER_NAME}/"
done
echo ""

if $DRY_RUN; then
  warn "Dry run: commands above will be skipped."
else
  echo -ne "${YELLOW}Proceed with upload? [y/N]${NC} "
  read -r CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    warn "Upload cancelled. Image processing will continue, but nothing will be uploaded."
    DRY_RUN=true
  fi
fi

# ── Prepare temp workspace ────────────────────────────────────────────────────
header "📁 Preparing workspace"

WORK_ROOT=$(mktemp -d)
mkdir -p "./output"

ok "Workspace: $WORK_ROOT"

# ── Process each image ────────────────────────────────────────────────────────
for i in "${!FILES[@]}"; do
  FILE="${FILES[$i]}"
  PROJECT_ID="${PROJECT_IDS[$i]}"
  FOLDER_NAME="${FOLDER_NAMES[$i]}"
  COVER_URL="${COVER_URLS[$i]}"
  CREDITS="${CREDITS_LIST[$i]}"

  header "🖼  Processing $PROJECT_ID"

  IMG_WORK_DIR="$WORK_ROOT/$FOLDER_NAME"
  mkdir -p "$IMG_WORK_DIR"
  WORK_SRC="$IMG_WORK_DIR/cover.jpg"

  cp "$FILE" "$WORK_SRC"

  # Step 1: Resize
  log "Resizing to 1600px wide"
  dims_before=$(identify -format "%wx%h" "$WORK_SRC")
  magick "$WORK_SRC" -resize 1600x "$WORK_SRC"
  dims_after=$(identify -format "%wx%h" "$WORK_SRC")
  ok "Resized: $dims_before → $dims_after"

  # Step 2: Compress (in place, this file is what gets uploaded)
  log "Compressing (quality: $QUALITY)"
  size_before=$(du -sh "$WORK_SRC" | cut -f1)
  magick "$WORK_SRC" -quality "$QUALITY" "$WORK_SRC"
  size_after=$(du -sh "$WORK_SRC" | cut -f1)
  ok "Compressed: ${size_before} → ${size_after}"

  # Step 3: Generate snippet
  log "Generating snippet"
  SNIPPET_FILE="$IMG_WORK_DIR/snippet.html"

  CREDITS_ESCAPED=$(printf '%s\n' "$CREDITS" | sed 's/[[\.*^$()+?{|]/\\&/g; s/&/\\\&/g')
  URL_ESCAPED=$(printf '%s\n' "$COVER_URL"   | sed 's/[[\.*^$()+?{|]/\\&/g; s/&/\\\&/g')

  cat > "$SNIPPET_FILE" << 'SNIPPET_EOF'
<!-- dark-mode-support -->

<style>
  .article--longform .article__media--wide { z-index: unset;}
  .article.article--longform > div { width: 100%;}
  @media (min-width: 800px) { .article--longform .article__heading { width: 100%; }}
  *:has(> .lmui-reset-parent-margins) { margin: 0 !important;}

  .lm-custom-cover {
    --cover-height: 80vh;
    background: #fff;
    width: 100%;
    height: auto;
    max-height: var(--cover-height);
    position: relative;
    margin: auto;
    display: grid;
    width: fit-content;
    margin: auto;
  }

  .lm-custom-cover > * {
    height: auto;
    max-height: var(--cover-height);
    width: 100%;
  }

  .lm-custom-cover img {
    height: 100%;
    width: 100%;
    object-fit: contain;
    max-width: 100%;
    font-size: 0;
    background: #000;
  }

  .lm-custom-cover__caption {
    font-family: Marr Sans, Arial, sans-serif;
    color: #ffffff;
    font-size: 13px;
    line-height: 1.42;
    font-weight: 400;
    position: absolute;
    bottom: 0;
    right: 0;
    margin: 0;
    padding: 12px;
    text-align: right;
  }

  .lm-custom-cover__credits {
    text-transform: uppercase;
    font-weight: 400;
    color: #eff0f3;
    font-size: 1.1rem;
    text-shadow: 0 0 8px #2a303b;
  }
</style>

<div class="lm-custom-cover" style="min-height:100px;">
  <div class="lm-custom-cover__background">
    <img src="[URL TO REPLACE]" />
    <p class="lm-custom-cover__caption">
      <span class="lm-custom-cover__credits">[TEXT TO REPLACE]</span>
    </p>
  </div>
</div>
SNIPPET_EOF

  sed -i '' "s|\[URL TO REPLACE\]|${URL_ESCAPED}|g"     "$SNIPPET_FILE"
  sed -i '' "s|\[TEXT TO REPLACE\]|${CREDITS_ESCAPED}|g" "$SNIPPET_FILE"

  ok "Snippet generated"

  # Save outputs
  OUTPUT_SNIPPET="./output/snippet-${FOLDER_NAME}.txt"
  cp "$SNIPPET_FILE" "$OUTPUT_SNIPPET"
  ok "Snippet saved → $OUTPUT_SNIPPET"

  OUTPUT_IMAGE="./output/cover-${PROJECT_ID}.jpg"
  cp "$WORK_SRC" "$OUTPUT_IMAGE"
  ok "Processed image saved → $OUTPUT_IMAGE"
done

# ── Upload to GCloud ───────────────────────────────────────────────────────────
header "☁️  Uploading to Google Cloud Storage"

if $DRY_RUN; then
  warn "Dry run: skipping upload and permissions"
else
  for FOLDER_NAME in "${FOLDER_NAMES[@]}"; do
    log "Syncing to: ${BUCKET}/${FOLDER_NAME}/"
    gsutil -m -h "Cache-Control:public, max-age=60" rsync -crpj txt "$WORK_ROOT/${FOLDER_NAME}/" "${BUCKET}/${FOLDER_NAME}/"

    log "Setting public read permissions on ${FOLDER_NAME}..."
    gsutil -m acl -r ch -u allUsers:R "${BUCKET}/${FOLDER_NAME}/"
  done
  ok "Upload complete, permissions set"
fi

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -rf "$WORK_ROOT"

# ── Summary ───────────────────────────────────────────────────────────────────
header "✅ Batch pipeline complete"
$DRY_RUN && warn "GCloud upload was skipped (dry run or cancelled)"

for i in "${!FILES[@]}"; do
  PROJECT_ID="${PROJECT_IDS[$i]}"
  FOLDER_NAME="${FOLDER_NAMES[$i]}"
  COVER_URL="${COVER_URLS[$i]}"
  echo ""
  echo -e "  ${BOLD}Project:${NC}      $PROJECT_ID"
  echo -e "  ${BOLD}Cover URL:${NC}    $COVER_URL"
  echo -e "  ${BOLD}Snippet:${NC}      ./output/snippet-${FOLDER_NAME}.txt"
  echo -e "  ${BOLD}Image:${NC}        ./output/cover-${PROJECT_ID}.jpg"
done
echo ""
