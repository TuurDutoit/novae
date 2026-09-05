#!/usr/bin/env node
// Full sync script - fetches each page via webfetch and downloads images
// This script tells the user which slugs to process
const fs = require('fs')
const path = require('path')

const manifest = require('../manifest.json')
const pagesDir = path.join(__dirname, '..', 'pages')

fs.mkdirSync(pagesDir, { recursive: true })

let total = 0
let missing = []

manifest.chapters.forEach(ch => {
  ch.pages.forEach(p => {
    total++
    const safeName = p.slug.replace(/\//g, '-')
    let found = false
    for (const ext of ['jpg', 'png', 'gif', 'webp']) {
      if (fs.existsSync(path.join(pagesDir, `${safeName}.${ext}`))) {
        found = true
        break
      }
    }
    if (!found) {
      missing.push(p)
    }
  })
})

console.log(`Total pages: ${total}`)
console.log(`Already downloaded: ${total - missing.length}`)
console.log(`Missing: ${missing.length}`)
console.log('')

if (missing.length === 0) {
  console.log('All pages downloaded!')
  process.exit(0)
}

const batchSize = 10
for (let i = 0; i < missing.length; i += batchSize) {
  const batch = missing.slice(i, i + batchSize)
  console.log(`\n--- Batch ${Math.floor(i / batchSize) + 1} ---`)
  batch.forEach(p => {
    console.log(`https://www.novaecomic.com/${p.slug}`)
  })
  if (i + batchSize < missing.length) {
    console.log('')
  }
}

console.log(`\nTo fetch: pipe the URLs above through webfetch, one at a time.`)
console.log(`Then run: node scripts/process-html.js tool-output/`)
console.log(`Where tool-output/ contains files named page-<safe-slug>.html with the webfetch HTML output.`)
