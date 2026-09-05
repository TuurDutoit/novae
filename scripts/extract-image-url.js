#!/usr/bin/env node
const manifest = require('../manifest.json')

const slug = process.argv[2]
if (!slug) {
  console.error('Usage: node extract-image-url.js <slug>')
  console.error('Reads HTML from stdin, extracts image URL, and downloads it')
  process.exit(1)
}

let html = ''
process.stdin.setEncoding('utf8')
process.stdin.on('data', (chunk) => (html += chunk))
process.stdin.on('end', () => {
  const match = html.match(/<img[^>]+id="cc-comic"[^>]+src="([^"]+)"/)
  if (!match) {
    console.error('No comic image found for', slug)
    process.exit(1)
  }
  const imgUrl = match[1]
  const ext = imgUrl.split('.').pop() || 'jpg'
  const filename = `../pages/${slug.replace(/\//g, '-')}.${ext}`

  const fs = require('fs')
  const https = require('https')

  const file = fs.createWriteStream(filename)
  https.get(imgUrl, (res) => {
    if (res.statusCode !== 200) {
      console.error(`Failed to download ${imgUrl}: ${res.statusCode}`)
      process.exit(1)
    }
    res.pipe(file)
    file.on('finish', () => {
      file.close()
      console.log(`Downloaded ${imgUrl} → ${filename}`)
    })
  }).on('error', (err) => {
    fs.unlink(filename, () => {})
    console.error(`Download error for ${slug}:`, err.message)
    process.exit(1)
  })
})
