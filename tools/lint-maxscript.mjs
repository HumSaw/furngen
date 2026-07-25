#!/usr/bin/env node
/**
 * lint-maxscript.mjs — static checks for the FurnGen MAXScript sources.
 *
 * MAXScript has no official linter and no compiler you can run in CI, so this
 * script encodes the failure modes that actually broke this project in 3ds Max:
 *
 *   1. unbalanced parentheses      -> "Unable to convert" / silent no-op
 *   2. unbalanced block comments   -> the rest of the file is swallowed
 *   3. trailing backslash + text   -> line continuation only works at EOL
 *   4. tabs / trailing whitespace  -> unreadable diffs across editors
 *   5. non-ASCII characters        -> the Listener mangles them on some locales
 *   6. undefined function calls    -> a typo'd fg* helper fails only at runtime
 *   7. module load order           -> a module calling a helper declared later
 *
 * Usage:
 *   node tools/lint-maxscript.mjs            # lint
 *   node tools/lint-maxscript.mjs --quiet    # errors only
 *
 * Exit code 0 = clean, 1 = at least one error.
 */

import { readFileSync, readdirSync } from "node:fs"
import { join, relative, basename } from "node:path"

const ROOT = process.cwd()
const SRC = join(ROOT, "src")
const MODULES = join(SRC, "modules")
const QUIET = process.argv.includes("--quiet")

/** Load order must match src/FurnGen.ms */
const LOAD_ORDER = ["core.ms", "geometry.ms", "materials.ms", "sofa.ms", "furniture.ms", "qa.ms", "ui.ms"]

const problems = []
const add = (level, file, line, msg) => problems.push({ level, file, line, msg })

/** Strip block and line comments plus string literals so scans see code only. */
function stripNonCode(text) {
  let out = ""
  let i = 0
  let inBlock = false
  let inString = false
  while (i < text.length) {
    const two = text.slice(i, i + 2)
    const ch = text[i]
    if (inBlock) {
      if (two === "*/") {
        inBlock = false
        i += 2
        continue
      }
      out += ch === "\n" ? "\n" : " "
      i += 1
      continue
    }
    if (inString) {
      if (ch === "\\") {
        out += "  "
        i += 2
        continue
      }
      if (ch === '"') inString = false
      out += ch === "\n" ? "\n" : " "
      i += 1
      continue
    }
    if (two === "/*") {
      inBlock = true
      out += "  "
      i += 2
      continue
    }
    if (two === "--") {
      while (i < text.length && text[i] !== "\n") {
        out += " "
        i += 1
      }
      continue
    }
    if (ch === '"') {
      inString = true
      out += " "
      i += 1
      continue
    }
    out += ch
    i += 1
  }
  if (inBlock) return { code: out, unterminatedBlock: true }
  return { code: out, unterminatedBlock: false }
}

function lintFile(absPath) {
  const file = relative(ROOT, absPath)
  const text = readFileSync(absPath, "utf8")
  const lines = text.split("\n")
  const { code, unterminatedBlock } = stripNonCode(text)

  if (unterminatedBlock) add("error", file, lines.length, "unterminated /* block comment */")

  // Parenthesis balance, comment- and string-aware
  let depth = 0
  let deepestNegativeLine = 0
  const codeLines = code.split("\n")
  for (let n = 0; n < codeLines.length; n++) {
    for (const ch of codeLines[n]) {
      if (ch === "(") depth += 1
      else if (ch === ")") {
        depth -= 1
        if (depth < 0 && !deepestNegativeLine) deepestNegativeLine = n + 1
      }
    }
  }
  if (depth > 0) add("error", file, lines.length, `${depth} unclosed "(" - MAXScript will fail to parse`)
  if (depth < 0) add("error", file, deepestNegativeLine || lines.length, `${-depth} extra ")"`)

  // Square bracket balance (point3 literals)
  let sq = 0
  for (const ch of code) {
    if (ch === "[") sq += 1
    else if (ch === "]") sq -= 1
  }
  if (sq !== 0) add("error", file, lines.length, `unbalanced square brackets (${sq > 0 ? "unclosed" : "extra"})`)

  lines.forEach((raw, idx) => {
    const n = idx + 1

    // A backslash continuation must be the last character on the line
    const cont = raw.match(/\\(.+)$/)
    if (cont && !cont[1].trim().startsWith("\\") && !/^\s*$/.test(cont[1]) && !raw.trimStart().startsWith("--")) {
      if (!raw.includes('"') && !raw.includes("\\\\")) {
        add("error", file, n, 'text after "\\" - line continuation must end the line')
      }
    }

    if (raw.includes("\t")) add("warn", file, n, "tab character - use 4 spaces")
    if (/[ \t]+$/.test(raw)) add("warn", file, n, "trailing whitespace")

    const nonAscii = raw.match(/[^\x00-\x7F]/g)
    if (nonAscii) {
      const unique = [...new Set(nonAscii)].join(" ")
      add("warn", file, n, `non-ASCII character(s): ${unique}`)
    }

    // Continuation lines cannot be wrapped further, so they are exempt
    const isContinuation = raw.trimEnd().endsWith("\\")
    if (raw.length > 120 && !isContinuation) {
      add("warn", file, n, `line is ${raw.length} chars (max 120)`)
    }
  })

  // Declared and called fg* helpers, for cross-module resolution
  const declared = new Set()
  for (const m of code.matchAll(/\bfn\s+(fg[A-Za-z0-9_]*)/g)) declared.add(m[1])
  const globals = new Set()
  for (const m of code.matchAll(/\bglobal\s+([A-Za-z0-9_]+)/g)) globals.add(m[1])
  const structs = new Set()
  for (const m of code.matchAll(/\bstruct\s+([A-Za-z0-9_]+)/g)) structs.add(m[1])

  const called = []
  for (const m of code.matchAll(/\b(fg[A-Za-z0-9_]*)/g)) {
    const name = m[1]
    const at = code.slice(0, m.index).split("\n").length
    called.push({ name, line: at })
  }

  return { file, base: basename(absPath), declared, globals, structs, called }
}

const moduleFiles = readdirSync(MODULES)
  .filter((f) => f.endsWith(".ms"))
  .sort((a, b) => LOAD_ORDER.indexOf(a) - LOAD_ORDER.indexOf(b))

for (const f of moduleFiles) {
  if (!LOAD_ORDER.includes(f)) {
    add("error", relative(ROOT, join(MODULES, f)), 1, "module is not listed in src/FurnGen.ms load order")
  }
}

const results = [...moduleFiles.map((f) => lintFile(join(MODULES, f))), lintFile(join(SRC, "FurnGen.ms"))]

// Cross-module symbol resolution respecting load order
const availableAt = new Map()
const running = new Set()
for (const r of results.filter((r) => r.base !== "FurnGen.ms")) {
  availableAt.set(r.base, new Set(running))
  for (const d of r.declared) running.add(d)
}

const everyDeclared = new Set()
for (const r of results) for (const d of r.declared) everyDeclared.add(d)

for (const r of results) {
  const visible = r.base === "FurnGen.ms" ? everyDeclared : new Set([...(availableAt.get(r.base) ?? []), ...r.declared])
  for (const c of r.called) {
    if (r.declared.has(c.name)) continue
    if (everyDeclared.has(c.name)) {
      if (!visible.has(c.name)) {
        add("error", r.file, c.line, `calls ${c.name}() before it is loaded - fix module order in src/FurnGen.ms`)
      }
      continue
    }
    add("error", r.file, c.line, `unknown helper ${c.name}() - not declared in any module`)
  }
}

// The loader must reference every module exactly once
const loader = readFileSync(join(SRC, "FurnGen.ms"), "utf8")
for (const f of LOAD_ORDER) {
  if (!loader.includes(`"${f}"`)) {
    add("error", "src/FurnGen.ms", 1, `load order is missing ${f}`)
  }
}

const errors = problems.filter((p) => p.level === "error")
const warnings = problems.filter((p) => p.level === "warn")

const shown = QUIET ? errors : problems
shown.sort((a, b) => a.file.localeCompare(b.file) || a.line - b.line)
for (const p of shown) {
  const tag = p.level === "error" ? "ERROR" : "warn "
  console.log(`${tag} ${p.file}:${p.line}  ${p.msg}`)
}

const fileCount = results.length
console.log(
  `\nlint-maxscript: ${fileCount} file(s), ${errors.length} error(s), ${warnings.length} warning(s), ` +
    `${everyDeclared.size} helper(s) resolved`,
)

process.exit(errors.length > 0 ? 1 : 0)
