#!/bin/bash
# Usage: bash scripts/dl.sh <slug>
# Fetches the page HTML via webfetch and downloads the image
SLUG="$1"
SAFE=$(echo "$SLUG" | tr '/' '-')
HTML_FILE=".tmp-$SAFE.html"

echo "Fetching $SLUG..."
webfetch format=html url="https://www.novaecomic.com/$SLUG" 2>&1 > "$HTML_FILE"

IMG_URL=$(grep -oP 'id="cc-comic"[^>]+src="\K[^"]+' "$HTML_FILE" | head -1)

if [ -z "$IMG_URL" ]; then
  echo "  No image found for $SLUG"
  rm -f "$HTML_FILE"
  exit 1
fi

EXT="${IMG_URL##*.}"
EXT=$(echo "$EXT" | tr -cd 'a-zA-Z')
[ -z "$EXT" ] && EXT="jpg"

echo "  Image: $IMG_URL"
curl -s -o "pages/$SAFE.$EXT" --max-time 60 "$IMG_URL" -w "  Downloaded: %{size_download} bytes\n"

rm -f "$HTML_FILE"
