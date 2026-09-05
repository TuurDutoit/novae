#!/bin/bash
set -euo pipefail

MANIFEST="manifest.json"
PAGES_DIR="pages"
SCRIPT_DIR="scripts"

ALL_PAGES=$(node -e "
  const m = require('./$MANIFEST');
  m.chapters.forEach(ch => ch.pages.forEach(p => {
    const slug = p.slug;
    const safeName = slug.replace(/\\//g, '-');
    const exists = require('fs').existsSync('$PAGES_DIR/' + safeName + '.jpg')
             || require('fs').existsSync('$PAGES_DIR/' + safeName + '.png')
             || require('fs').existsSync('$PAGES_DIR/' + safeName + '.gif')
             || require('fs').existsSync('$PAGES_DIR/' + safeName + '.webp');
    if (!exists) console.log(slug);
  }));
")

echo "Pages to download: $(echo "$ALL_PAGES" | wc -l)"

for SLUG in $ALL_PAGES; do
  SAFE_NAME=$(echo "$SLUG" | tr '/' '-')

  echo ""
  echo "=== Fetching: https://www.novaecomic.com/$SLUG ==="

  HTML=$(curl -s \
    -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
    -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
    -H "Accept-Language: en-US,en;q=0.5" \
    --max-time 30 \
    "https://www.novaecomic.com/$SLUG" 2>/dev/null)

  if [ -z "$HTML" ]; then
    echo "  ✗ Empty response - skipping"
    echo "$SLUG" >> "$SCRIPT_DIR/remaining.txt"
    continue
  fi

  # Check if we got the Cloudflare challenge page
  if echo "$HTML" | grep -q "challenge-platform\|cf-browser-racing\|Checking your browser"; then
    echo "  ✗ Cloudflare challenge - skipping"
    echo "$SLUG" >> "$SCRIPT_DIR/remaining.txt"
    continue
  fi

  IMG_URL=$(echo "$HTML" | grep -oP 'id="cc-comic"[^>]+src="\K[^"]+')

  if [ -z "$IMG_URL" ]; then
    echo "  ✗ No comic image found"
    echo "$SLUG" >> "$SCRIPT_DIR/remaining.txt"
    continue
  fi

  EXT=$(echo "$IMG_URL" | grep -oP '\.[a-zA-Z]+$' || echo ".jpg")
  FILENAME="$PAGES_DIR/$SAFE_NAME$EXT"

  echo "  Image: $IMG_URL"
  curl -s -o "$FILENAME" --max-time 60 "$IMG_URL"
  echo "  ✓ Downloaded to $FILENAME"

  sleep 0.5
done

echo ""
echo "=== Sync complete ==="
if [ -f "$SCRIPT_DIR/remaining.txt" ]; then
  echo "Pages blocked by Cloudflare: $(wc -l < "$SCRIPT_DIR/remaining.txt")"
  echo "See $SCRIPT_DIR/remaining.txt"
fi
