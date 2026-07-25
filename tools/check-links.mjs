#!/usr/bin/env node
/*
    check-links.mjs — validate internal Markdown links.

    Catches the two mistakes that actually happen while editing a bilingual
    docs tree: a link to a file that was renamed, and a link to a heading
    anchor that was reworded. Both render as normal blue links on GitHub and
    only fail when a reader clicks them, so they are worth enforcing in CI.

    External links (http/https/mailto) are deliberately NOT checked — that
    would make CI depend on the network and on third-party uptime.

    Usage:  node tools/check-links.mjs

    Exits non-zero when any internal link is broken.
*/

import fs from "node:fs/promises"
import path from "node:path"

const root = process.cwd()
const SKIP_DIRS = new Set(["node_modules", ".git", ".next", "dist", ".vercel"])

/** Recursively collect every Markdown file we own. */
async function collect(dir, out = []) {
  for (const entry of await fs.readdir(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      if (SKIP_DIRS.has(entry.name)) continue
      await collect(path.join(dir, entry.name), out)
    } else if (entry.name.endsWith(".md")) {
      out.push(path.join(dir, entry.name))
    }
  }
  return out
}

/*
    Mirror GitHub's heading-anchor algorithm: lowercase, strip formatting and
    punctuation, then hyphenate whitespace. The Cyrillic range is kept so the
    Russian docs resolve too -- GitHub does support non-ASCII anchors.
*/
function slugify(heading) {
  return heading
    .trim()
    .toLowerCase()
    .replace(/[`*_]/g, "")
    .replace(/[^\w\s\u0400-\u04ff-]/g, "")
    .replace(/\s+/g, "-")
    .replace(/^-+|-+$/g, "")
}

/** Strip fenced code blocks so example snippets are not scanned for links. */
const stripCode = (s) => s.replace(/```[\s\S]*?```/g, "")

async function main() {
  const files = await collect(root)
  const anchors = new Map()
  const sources = new Map()

  for (const file of files) {
    const text = await fs.readFile(file, "utf8")
    sources.set(file, text)
    const found = new Set()
    for (const [, heading] of stripCode(text).matchAll(/^#{1,6}\s+(.*)$/gm)) {
      found.add(slugify(heading))
    }
    anchors.set(file, found)
  }

  const problems = []

  for (const file of files) {
    const body = stripCode(sources.get(file))
    for (const [, label, target] of body.matchAll(/\[([^\]]*)\]\(([^)\s]+)\)/g)) {
      if (/^(https?:|mailto:|#!)/.test(target)) continue

      const [rawPath, rawFragment = ""] = target.split("#")
      const fragment = decodeURIComponent(rawFragment)
      const resolved = rawPath ? path.resolve(path.dirname(file), rawPath) : file

      if (rawPath) {
        const exists = await fs.stat(resolved).catch(() => null)
        if (!exists) {
          problems.push(`${path.relative(root, file)}: missing file -> ${target}   [${label}]`)
          continue
        }
      }

      // Only Markdown files have anchors we can verify.
      if (fragment && anchors.has(resolved) && !anchors.get(resolved).has(fragment)) {
        problems.push(`${path.relative(root, file)}: missing anchor -> ${target}   [${label}]`)
      }
    }
  }

  for (const problem of problems) console.error(`check-links: ${problem}`)

  console.log(
    `check-links: ${files.length} file(s), ${problems.length} broken link(s)`,
  )
  if (problems.length > 0) process.exit(1)
}

main().catch((err) => {
  console.error("check-links: unexpected failure")
  console.error(err)
  process.exit(1)
})
