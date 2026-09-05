# Novae Reader

Offline-first PWA reader for the [Novae webcomic](https://www.novaecomic.com/).

## Local Development

Open `index.html` in a browser, or serve with any static server:

```bash
python3 -m http.server 8080
```

## Syncing New Pages

See `skills/novae-sync/SKILL.md` for the full workflow.

## Structure

- `index.html` — PWA reader app
- `sw.js` — Service worker for offline caching
- `app.webmanifest` — PWA manifest
- `manifest.json` — Chapter and page index
- `pages/` — Downloaded comic page images
- `scripts/` — Helper utilities
