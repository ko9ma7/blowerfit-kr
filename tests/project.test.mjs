import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile, access } from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const mustExist = [
  'web/index.html','web/app.js','web/styles.css','web/manifest.webmanifest','web/sw.js',
  'web/favicon.svg','web/favicon.ico','web/apple-touch-icon.png','web/og-image.png',
  'web/404.html','.github/workflows/deploy.yml','github-bootstrap.cmd','README.md'
]

test('required GitHub Pages assets exist', async () => {
  for (const rel of mustExist) await access(path.join(root, rel))
})

test('index contains deployment and social metadata', async () => {
  const html = await readFile(path.join(root, 'web/index.html'), 'utf8')
  for (const token of ['og:title','og:image','twitter:card','manifest.webmanifest','application/ld+json']) {
    assert.ok(html.includes(token), token)
  }
})

test('app exposes at least five engineering selection tabs', async () => {
  const app = await readFile(path.join(root, 'web/app.js'), 'utf8')
  const expected = ['flow','pressure','openings','airknife','duct','vacuum','application']
  for (const tab of expected) assert.ok(app.includes(`['${tab}'`), tab)
})
