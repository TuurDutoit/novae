const CACHE = 'novae-v1'

self.addEventListener('install', (e) => {
  self.skipWaiting()
})

self.addEventListener('activate', (e) => {
  e.waitUntil(clients.claim())
})

self.addEventListener('fetch', (e) => {
  const url = new URL(e.request.url)
  if (url.origin !== location.origin) return

  const base = self.location.pathname.replace(/\/[^/]*$/, '/')
  const p = url.pathname
  if (p.startsWith(base + 'pages/') || p === base + 'manifest.json' || p === base + 'index.html' || p === base + 'app.webmanifest' || p === base + 'sw.js') {
    e.respondWith(
      caches.open(CACHE).then((cache) =>
        cache.match(e.request).then((cached) => {
          const fetchPromise = fetch(e.request).then((res) => {
            if (res.ok) cache.put(e.request, res.clone())
            return res
          }).catch(() => cached)
          return cached || fetchPromise
        })
      )
    )
  }
})
