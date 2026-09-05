# Novae Comic Sync

Fetch new pages from the Novae webcomic website and update your local archive.

## How it works

The Novae website uses Cloudflare to block curl/wget from fetching HTML pages. Images are served directly and are accessible via curl.

The sync process uses the `webfetch` tool (which bypasses Cloudflare) to fetch each new page's HTML, extracts the image URL from `<img id="cc-comic">`, and downloads the image with curl.

## Steps

### 1. Fetch the archive page

```
webfetch format=html url=https://www.novaecomic.com/comic/archive
```

This returns a `<select name="comic">` with `<option value="comic/...">label</option>` elements.

### 2. Parse the archive into the manifest

Compare the fetched archive against the existing `manifest.json`. The archive lists all pages with slugs like `comic/chap-X-pgNNN` and labels like `"January 1, 2024 - Chap X - PGNNN"`.

Group pages by chapter. Chapters are identified by:
- Chapter cover pages (e.g. `comic/chapter-19-threshold`, `comic/chapter-18-event-horizon`)
- Pages following the pattern `comic/chap-X-pgNNN` belong to chapter X
- Mini-comics, illustrations, announcements, and crossover pages may appear between chapters
- When the chapter number in the slug changes, that starts a new chapter
- Some chapters span multiple parts (e.g. Chapter 3 "The Space Between / Gravity" has slugs `chap-3-*` for both parts)
- Special pages (bonus, extras, factoids, pride, lore encyclopedia, etc.) should be grouped with the current chapter unless they clearly start a new section
- Crossover pages, announcements, and return-date posts should all be included

The chapter boundaries from the current `manifest.json` are the ground truth for existing content. Only add NEW pages (not already in the manifest).

### 3. Fetch each new page and download the image

For each new page slug that doesn't have an image yet:

1. Fetch the page:
   ```
   webfetch format=html url=https://www.novaecomic.com/{slug}
   ```

2. Extract the image URL from the HTML:
   ```html
   <img id="cc-comic" src="https://www.novaecomic.com/comics/...jpg" />
   ```
   Look for `id="cc-comic"` and capture the `src` attribute.

3. Download the image:
   ```bash
   curl -s -o "pages/{slug-safe-name}.jpg" "{image-url}"
   ```
   where `{slug-safe-name}` is the slug with `/` replaced by `-`.

### 4. Update manifest.json

Add the new pages to their respective chapters in `manifest.json`. Each page entry has:
```json
{
  "slug": "comic/chap-18-pg997",
  "label": "August 20, 2026 - Chap 19-PG997"
}
```

### 5. Commit and push

```bash
git add manifest.json pages/
git commit -m "sync: add new comic pages"
git push
```

### Notes

- Images are large (700KB-2MB each). Use `curl --max-time 60` per image.
- The webfetch tool is the only way to get past Cloudflare for HTML pages.
- Image URLs are directly accessible via curl (Cloudflare cache HIT).
- Image filenames use timestamps that aren't predictable, so you MUST fetch each page's HTML.
- After syncing, the PWA at index.html will serve the new content via GitHub Pages.
