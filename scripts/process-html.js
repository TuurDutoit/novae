#!/usr/bin/env node
const fs = require('fs')
const path = require('path')

const htmlDir = process.argv[2] || 'tool-output'

fs.readdirSync(htmlDir).filter(f => f.startsWith('page-') && f.endsWith('.html')).forEach(f => {
  const html = fs.readFileSync(path.join(htmlDir, f), 'utf8')
  const slug = f.replace(/^page-/, '').replace(/\.html$/, '')
  const match = html.match(/<img[^>]+id="cc-comic"[^>]+src="([^"]+)"/)
  if (!match) {
    console.error('No image in', f)
    return
  }
  const imgUrl = match[1]
  const ext = imgUrl.split('.').pop() || 'jpg'
  const filename = `pages/${slug.replace(/[\/\\?]/g, '-')}.${ext}`

  if (fs.existsSync(filename)) {
    console.log('Already exists:', filename)
    return
  }

  const { execSync } = require('child_process')
  console.log(`Downloading ${imgUrl} -> ${filename}`)
  try {
    execSync(`curl -s -o "${filename}" --max-time 60 "${imgUrl}"`, { stdio: 'pipe' })
    console.log(`  OK (${fs.statSync(filename).size} bytes)`)
  } catch (e) {
    console.error(`  FAIL: ${e.message}`)
  }
})
