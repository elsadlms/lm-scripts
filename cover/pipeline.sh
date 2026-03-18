#!/bin/bash
# =============================================================================
# cover-pipeline.sh
# Automates cover image processing and snippet generation for Le Monde
#
# Usage:
#   ./cover-pipeline.sh -c "Image credits" [-q quality] [--dry-run]
#
# Examples:
#   ./cover-pipeline.sh -c "© Jane Doe / AFP"
#   ./cover-pipeline.sh -c "© Jane Doe / AFP" -q 80
#   ./cover-pipeline.sh -c "© Jane Doe / AFP" --dry-run
#
# Reads image from:  ./input/<filename>.jpg  (first jpg found)
# Project ID:        derived from the jpg filename (without extension)
# Outputs:           ./output/cover.jpg  +  ./snippet-<folder>.html
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
CREDITS=""
QUALITY=85

DRY_RUN=false

# Handle --dry-run separately (getopts doesn't support long flags)
ARGS=()
for arg in "$@"; do
  [ "$arg" = "--dry-run" ] && DRY_RUN=true || ARGS+=("$arg")
done
set -- "${ARGS[@]}"

while getopts "c:q:" opt; do
  case $opt in
    c) CREDITS="$OPTARG" ;;
    q) QUALITY="$OPTARG" ;;
    *) echo "Usage: $0 -c \"Credits text\" [-q quality] [--dry-run]"; exit 1 ;;
  esac
done

# ── Validate inputs ───────────────────────────────────────────────────────────
header "🔍 Validating inputs"

INPUT_FOLDER="./input"
[ ! -d "$INPUT_FOLDER" ] && error "Folder $INPUT_FOLDER not found. Please create it and place your JPG inside."

# Find the first jpg in ./input
FILE=$(find "$INPUT_FOLDER" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) | sort | head -n 1)
[ -z "$FILE" ] && error "No JPG file found in $INPUT_FOLDER"

# Derive project ID from filename (strip extension)
FILENAME=$(basename "$FILE")
PROJECT_ID="${FILENAME%.*}"

ok "File:       $FILE"
ok "Project ID: $PROJECT_ID"
ok "Credits:    $CREDITS"
ok "Quality:    $QUALITY"
$DRY_RUN && warn "Mode:       DRY RUN — gcloud commands will be printed but not executed"

# ── Derive folder name and URL ────────────────────────────────────────────────
YYMM=$(date +"%y%m")
FOLDER_NAME="${YYMM}-cover-${PROJECT_ID}"
BUCKET_PATH="${BUCKET}/${FOLDER_NAME}/"
COVER_URL="${ASSETS_BASE_URL}/${FOLDER_NAME}/cover.jpg"

ok "Folder:     $FOLDER_NAME"
ok "URL:        $COVER_URL"

# ── Check gcloud authentication ───────────────────────────────────────────────
header "🔐 Checking GCloud authentication"

if ! gcloud auth print-access-token &>/dev/null; then
  warn "You are not logged in to GCloud."
  echo -e "  Launching ${BOLD}gcloud auth login${NC}..."
  gcloud auth login
  # Re-check after login
  if ! gcloud auth print-access-token &>/dev/null; then
    error "GCloud authentication failed. Please run 'gcloud auth login' manually and retry."
  fi
fi
ok "Authenticated with GCloud"

# ── Show upload plan + confirm ────────────────────────────────────────────────
header "☁️  GCloud upload plan"
echo ""
echo -e "  ${BOLD}1.${NC} gsutil -m -h \"Cache-Control:public, max-age=60\" rsync -crpj txt ./output/ ${BUCKET_PATH}"
echo -e "  ${BOLD}2.${NC} gsutil -m acl -r ch -u allUsers:R ${BUCKET_PATH}"
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

WORK_DIR=$(mktemp -d)
WORK_INPUT="$WORK_DIR/input"
WORK_OUTPUT="$WORK_DIR/output"
mkdir -p "$WORK_INPUT" "$WORK_OUTPUT"

cp "$FILE" "$WORK_INPUT/cover.jpg"
ok "Image copied to workspace"

# ── Step 1: Resize ────────────────────────────────────────────────────────────
header "📐 Step 1/4 — Resizing to 1600px wide"

dims_before=$(identify -format "%wx%h" "$WORK_INPUT/cover.jpg")
log "Original dimensions: $dims_before"

magick "$WORK_INPUT/cover.jpg" -resize 1600x "$WORK_INPUT/cover.jpg"

dims_after=$(identify -format "%wx%h" "$WORK_INPUT/cover.jpg")
ok "Resized to: $dims_after"

# ── Step 2: Compress ──────────────────────────────────────────────────────────
header "🗜  Step 2/4 — Compressing (quality: $QUALITY)"

magick "$WORK_INPUT/cover.jpg" -quality "$QUALITY" "$WORK_OUTPUT/cover.jpg"
size_before=$(du -sh "$WORK_INPUT/cover.jpg" | cut -f1)
size_after=$(du -sh "$WORK_OUTPUT/cover.jpg"  | cut -f1)
ok "Compressed: ${size_before} → ${size_after}"

# ── Step 3: Upload to GCloud ──────────────────────────────────────────────────
header "☁️  Step 3/4 — Uploading to Google Cloud Storage"

if $DRY_RUN; then
  warn "Dry run: skipping upload and permissions"
else
  log "Syncing to: $BUCKET_PATH"
  gsutil -m -h "Cache-Control:public, max-age=60" rsync -crpj txt "$WORK_OUTPUT/" "$BUCKET_PATH"
  ok "Upload complete"

  log "Setting public read permissions..."
  gsutil -m acl -r ch -u allUsers:R "$BUCKET_PATH"
  ok "Permissions set"
fi

# ── Step 4: Generate snippet ──────────────────────────────────────────────────
header "📝 Step 4/4 — Generating code snippet"

SNIPPET_FILE="$WORK_DIR/snippet.html"

# Escape special sed characters
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

sed -i '' "s|\[URL TO REPLACE\]|${URL_ESCAPED}|g"      "$SNIPPET_FILE"
sed -i '' "s|\[TEXT TO REPLACE\]|${CREDITS_ESCAPED}|g"  "$SNIPPET_FILE"

ok "Snippet generated"

# ── Save outputs ──────────────────────────────────────────────────────────────
mkdir -p ./output
OUTPUT_SNIPPET="./output/snippet-${FOLDER_NAME}.txt"
cp "$SNIPPET_FILE" "$OUTPUT_SNIPPET"
ok "Snippet saved → $OUTPUT_SNIPPET"

cp "$WORK_OUTPUT/cover.jpg" "./output/cover.jpg"
ok "Processed image saved → ./output/cover.jpg"

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -rf "$WORK_DIR"

# ── Summary ───────────────────────────────────────────────────────────────────
header "✅ Pipeline complete"
echo ""
echo -e "  ${BOLD}Folder name:${NC}  $FOLDER_NAME"
echo -e "  ${BOLD}Cover URL:${NC}    $COVER_URL"
echo -e "  ${BOLD}Snippet:${NC}      $OUTPUT_SNIPPET"
echo -e "  ${BOLD}Image:${NC}        ./output/cover.jpg"
$DRY_RUN && warn "GCloud upload was skipped (dry run or cancelled)"
echo ""
echo -e "${GREEN}${BOLD}Snippet preview:${NC}"
echo "────────────────────────────────────────"
cat "$OUTPUT_SNIPPET"
echo ""
echo "────────────────────────────────────────"