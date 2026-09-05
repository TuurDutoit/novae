#!/bin/bash
# Batch download comic pages using webfetch + curl
# Usage: bash scripts/batch-dl.sh [limit]
# Processes manifest.json, fetches missing pages, extracts image URLs, downloads

set -euo pipefail
LIMIT="${1:-5}"

MANIFEST="manifest.json"
PAGES_DIR="pages"
SCRIPT_DIR="scripts"

process_page() {
  local SLUG="$1"
  local SAFE=$(echo "$SLUG" | tr '/' '-')
  
  # Skip if already downloaded
  for ext in jpg png gif webp; do
    if [ -f "$PAGES_DIR/$SAFE.$ext" ]; then
      return 0
    fi
  done

  echo "==> $SLUG"
  
  # Step 1: The user/future-agent must call webfetch for each slug
  # and pass the HTML output. This script reads from a cached file.
  local HTML_FILE=".tmp-$SAFE.html"
  
  if [ ! -f "$HTML_FILE" ]; then
    echo "  (no cached HTML - fetch with webfetch first)"
    return 1
  fi
  
  local IMG_URL=$(grep -oP 'id="cc-comic"[^>]+src="\K[^"]+' "$HTML_FILE" | head -1)
  if [ -z "$IMG_URL" ]; then
    echo "  no image found"
    rm -f "$HTML_FILE"
    return 1
  fi
  
  local EXT="${IMG_URL##*.}"
  EXT=$(echo "$EXT" | tr -cd 'a-zA-Z')
  [ -z "$EXT" ] && EXT="jpg"
  
  curl -s -o "$PAGES_DIR/$SAFE.$EXT" --max-time 60 "$IMG_URL" -w "  downloaded (%{size_download} bytes)\n"
  rm -f "$HTML_FILE"
}

# Get total count from manifest
TOTAL=$(node -e "
  const m = require('./$MANIFEST');
  let c = 0;
  m.chapters.forEach(ch => ch.pages.forEach(p => { c++; }));
  console.log(c);
")

echo "Total pages in manifest: $TOTAL"
echo "Already in pages/: $(ls $PAGES_DIR/*.jpg $PAGES_DIR/*.png 2>/dev/null | wc -l)"
echo ""
echo "Note: This script requires .tmp-<slug>.html files created by webfetch."
echo "To create them, use the webfetch tool:"
echo "  webfetch format=html url=https://www.novaecomic.com/{slug}"
echo "  Save output to .tmp-<slug-sanitized>.html"
echo "  Then re-run this script."
echo ""
echo "Alternatively, for the initial sync, run the full-sync.js script instead:"
echo "  node scripts/full-sync.js"
