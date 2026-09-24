import { cp, mkdir, rm, readFile, writeFile } from 'node:fs/promises'
import { dirname, resolve, join } from 'node:path'
import { fileURLToPath } from 'node:url'

// IMPORTANT: fileURLToPath() is required for Windows.
// Using new URL(...).pathname turns C:\\... into /C:/..., which can become C:\\C:\\...
// after path.resolve().
const scriptDir = dirname(fileURLToPath(import.meta.url))
const root = resolve(scriptDir, '..')
const src = join(root, 'web')
const dist = join(root, 'dist')

await rm(dist, { recursive: true, force: true })
await mkdir(dist, { recursive: true })
await cp(src, dist, { recursive: true })

const siteUrl = process.env.VITE_SITE_URL || 'http://localhost:5173/'
for (const file of ['index.html', 'robots.txt', 'sitemap.xml']) {
  const p = join(dist, file)
  try {
    const text = await readFile(p, 'utf8')
    await writeFile(p, text.replaceAll('__SITE_URL__', siteUrl), 'utf8')
  } catch {
    // Optional metadata file; skip if not present.
  }
}

console.log(`[build] copied static site -> ${dist} (site=${siteUrl})`)
