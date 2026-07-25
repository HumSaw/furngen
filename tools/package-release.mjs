#!/usr/bin/env node
/**
 * package-release.mjs
 * -------------------
 * Builds a distributable archive that an artist can unzip straight into
 * 3ds Max. The archive contains only what the tool needs at runtime:
 *
 *   FurnGen/
 *     FurnGen.ms          <- the file you run
 *     modules/*.ms
 *     INSTALL.txt
 *     LICENSE
 *
 * The version is read from src/modules/core.ms so the archive name can
 * never drift from the version the script actually reports.
 *
 * Usage:
 *   node tools/package-release.mjs            # -> dist/FurnGen-1.0.0.zip
 *   node tools/package-release.mjs --out build
 */

import { execFileSync } from "node:child_process"
import fs from "node:fs/promises"
import path from "node:path"
import zlib from "node:zlib"
import { promisify } from "node:util"

const deflateRaw = promisify(zlib.deflateRaw)
const root = process.cwd()

const MODULES = [
  "core.ms",
  "geometry.ms",
  "materials.ms",
  "sofa.ms",
  "furniture.ms",
  "qa.ms",
  "ui.ms",
]

function arg(name, fallback) {
  const i = process.argv.indexOf(`--${name}`)
  return i !== -1 && process.argv[i + 1] ? process.argv[i + 1] : fallback
}

/* ------------------------------------------------------------------ *
 * Minimal ZIP writer (deflate, no external dependency)
 * Keeps the packager portable: no `zip` binary required, so it behaves
 * identically on a developer machine, on macOS and in CI.
 * ------------------------------------------------------------------ */

const CRC_TABLE = (() => {
  const t = new Int32Array(256)
  for (let i = 0; i < 256; i++) {
    let c = i
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1
    t[i] = c
  }
  return t
})()

function crc32(buf) {
  let c = -1
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8)
  return (c ^ -1) >>> 0
}

/** MS-DOS date/time pair used by the ZIP header. UTC, so the stamp does not
 * depend on the builder's timezone. */
function dosStamp(date) {
  const year = Math.max(1980, date.getUTCFullYear())
  return {
    time: (date.getUTCHours() << 11) | (date.getUTCMinutes() << 5) | (date.getUTCSeconds() >> 1),
    date: ((year - 1980) << 9) | ((date.getUTCMonth() + 1) << 5) | date.getUTCDate(),
  }
}

/**
 * Entry timestamps come from the last commit (or SOURCE_DATE_EPOCH), not the
 * clock, so the same commit produces a byte-identical archive locally and in
 * CI. UTC keeps the DOS stamp independent of the builder's timezone.
 */
function buildDate() {
  const epoch = process.env.SOURCE_DATE_EPOCH
  if (epoch && /^\d+$/.test(epoch)) return new Date(Number(epoch) * 1000)
  try {
    const ct = execFileSync("git", ["log", "-1", "--format=%ct"], { cwd: root }).toString().trim()
    if (/^\d+$/.test(ct)) return new Date(Number(ct) * 1000)
  } catch {
    /* not a git checkout — fall through */
  }
  return new Date()
}

async function writeZip(zipPath, entries) {
  const stamp = dosStamp(buildDate())
  const locals = []
  const centrals = []
  let offset = 0

  for (const entry of entries) {
    const name = Buffer.from(entry.name, "utf8")
    const raw = Buffer.from(entry.data)
    const deflated = await deflateRaw(raw, { level: 9 })
    // Store uncompressed when deflate does not actually help.
    const useDeflate = deflated.length < raw.length
    const body = useDeflate ? deflated : raw
    const method = useDeflate ? 8 : 0
    const crc = crc32(raw)

    const local = Buffer.alloc(30)
    local.writeUInt32LE(0x04034b50, 0)
    local.writeUInt16LE(20, 4) // version needed
    local.writeUInt16LE(0x0800, 6) // UTF-8 filename flag
    local.writeUInt16LE(method, 8)
    local.writeUInt16LE(stamp.time, 10)
    local.writeUInt16LE(stamp.date, 12)
    local.writeUInt32LE(crc, 14)
    local.writeUInt32LE(body.length, 18)
    local.writeUInt32LE(raw.length, 22)
    local.writeUInt16LE(name.length, 26)
    local.writeUInt16LE(0, 28)
    locals.push(local, name, body)

    const central = Buffer.alloc(46)
    central.writeUInt32LE(0x02014b50, 0)
    central.writeUInt16LE(0x031e, 4) // made by UNIX
    central.writeUInt16LE(20, 6)
    central.writeUInt16LE(0x0800, 8)
    central.writeUInt16LE(method, 10)
    central.writeUInt16LE(stamp.time, 12)
    central.writeUInt16LE(stamp.date, 14)
    central.writeUInt32LE(crc, 16)
    central.writeUInt32LE(body.length, 20)
    central.writeUInt32LE(raw.length, 24)
    central.writeUInt16LE(name.length, 28)
    central.writeUInt32LE((entry.mode ?? 0o644) << 16, 38) // external attrs
    central.writeUInt32LE(offset, 42)
    centrals.push(central, name)

    offset += local.length + name.length + body.length
  }

  const centralBuf = Buffer.concat(centrals)
  const end = Buffer.alloc(22)
  end.writeUInt32LE(0x06054b50, 0)
  end.writeUInt16LE(entries.length, 8)
  end.writeUInt16LE(entries.length, 10)
  end.writeUInt32LE(centralBuf.length, 12)
  end.writeUInt32LE(offset, 16)

  await fs.writeFile(zipPath, Buffer.concat([...locals, centralBuf, end]))
}

async function readVersion() {
  const core = await fs.readFile(path.join(root, "src/modules/core.ms"), "utf8")
  const m = core.match(/global\s+FurnGen_Version\s*=\s*"([^"]+)"/)
  if (!m) throw new Error("FurnGen_Version not found in src/modules/core.ms")
  return m[1]
}

const INSTALL = (version) => `FurnGen ${version}
${"=".repeat(9 + version.length)}

Procedural furniture generator for Autodesk 3ds Max.

INSTALL
-------
1. Copy this entire "FurnGen" folder anywhere on disk. Keep the folder
   intact: FurnGen.ms locates its modules relative to its own path.

2. In 3ds Max: Scripting > Run Script...
   Select FurnGen.ms and press Open.

3. The FurnGen panel opens. Press GENERATE.

OPTIONAL: PERMANENT TOOLBAR BUTTON
----------------------------------
After the first run, type this in the MAXScript Listener:

    FurnGenRegisterMacro()

Then use Customize > Customize User Interface > Toolbars, choose the
category "FurnGen", and drag "FurnGen Panel" onto any toolbar.

REQUIREMENTS
------------
- 3ds Max 2020 or newer
- Corona Renderer is optional. When Corona is installed AND is the active
  renderer, FurnGen builds Corona materials. Otherwise it builds
  PhysicalMaterial, which renders correctly in Scanline, Arnold and ART.

RECOMMENDED SCENE SETUP
-----------------------
Customize > Units Setup > System Unit Scale = Centimeters.
All FurnGen geometry is authored in centimetres. The built-in QA check
warns you when the scene uses different system units.

TROUBLESHOOTING
---------------
Every generated item is validated automatically. Read the status line at
the bottom of the panel, and open the MAXScript Listener (F11) for the
full report. Errors are printed with a "FurnGen" prefix.
`

async function main() {
  const version = await readVersion()
  const outDir = path.join(root, arg("out", "dist"))
  await fs.mkdir(outDir, { recursive: true })

  const entries = []
  const add = async (name, file) => {
    entries.push({ name, data: await fs.readFile(file) })
  }

  await add("FurnGen/FurnGen.ms", path.join(root, "src/FurnGen.ms"))
  for (const m of MODULES) {
    await add(`FurnGen/modules/${m}`, path.join(root, "src/modules", m))
  }

  entries.push({ name: "FurnGen/INSTALL.txt", data: Buffer.from(INSTALL(version), "utf8") })

  const license = path.join(root, "LICENSE")
  if (await fs.stat(license).catch(() => null)) {
    await add("FurnGen/LICENSE", license)
  }

  const zipPath = path.join(outDir, `FurnGen-${version}.zip`)
  await writeZip(zipPath, entries)

  const { size } = await fs.stat(zipPath)
  console.log(`package-release: ${path.relative(root, zipPath)} (${(size / 1024).toFixed(1)} KB)`)
  console.log(`package-release: version ${version}, ${entries.length} file(s)`)
}

main().catch((err) => {
  console.error(`package-release: ${err.message}`)
  process.exit(1)
})
