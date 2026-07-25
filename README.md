<div align="center">

# FurnGen

**Procedural furniture generator for Autodesk 3ds Max.**

Generate render-ready sofas, beds, chairs, tables, storage and decor — or an entire
furnished room — from a single panel. Every result is reproducible from its seed.

[![CI](https://github.com/HumSaw/furngen/actions/workflows/ci.yml/badge.svg)](https://github.com/HumSaw/furngen/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-black.svg)](LICENSE)
[![3ds Max](https://img.shields.io/badge/3ds%20Max-2020%2B-0696D7.svg)](https://www.autodesk.com/products/3ds-max)
[![MAXScript](https://img.shields.io/badge/MAXScript-native-1f6feb.svg)](docs/en/architecture.md)

[Getting started](docs/en/getting-started.md) ·
[User guide](docs/en/user-guide.md) ·
[Architecture](docs/en/architecture.md) ·
[Extending](docs/en/extending.md) ·
[Русская документация](docs/ru/README.md)

</div>

---

## What it does

FurnGen builds furniture the way a modeller would: a frame, a filling that pushes
against its cover, folds where fabric sags, and a seam that catches the light. It
does this procedurally, so no two generated pieces are identical — but the same
seed always rebuilds the same piece, down to the tilt of each cushion.

| | |
|---|---|
| **28 furniture types** | across six categories, all at real-world scale in centimetres |
| **8 style presets** | each driving proportions, armrest shape, leg type and palette |
| **5 upholstery fabrics** | bouclé, velvet, linen, cotton, leather — each with its own bump and sheen |
| **2 room sets** | a living room and a bedroom, coordinated in one click |
| **Renderer-agnostic** | Corona when it is active, PhysicalMaterial everywhere else |
| **Built-in QA** | every item is validated for scale, materials, geometry and naming |

## Install

**Requirements:** 3ds Max 2020 or newer. Corona Renderer is optional.

1. Download the latest archive from [Releases](https://github.com/HumSaw/furngen/releases), or build it yourself:

   ```bash
   node tools/package-release.mjs   # -> dist/FurnGen-1.0.0.zip
   ```

2. Unzip anywhere on disk. Keep the folder intact — `FurnGen.ms` locates its
   modules relative to its own path.

3. In 3ds Max: **Scripting → Run Script…**, select `FurnGen.ms`, press **Open**.

4. Optional, for a permanent toolbar button — run this once in the Listener:

   ```maxscript
   FurnGenRegisterMacro()
   ```

   Then **Customize → Customize User Interface → Toolbars**, category
   **FurnGen**, and drag **FurnGen Panel** onto a toolbar.

> **Set your units.** FurnGen authors everything in centimetres. Use
> **Customize → Units Setup → System Unit Scale = Centimeters**. The QA check
> warns you when the scene disagrees.

## Quick start

Press **GENERATE**. That is the whole workflow.

To explore, press **Randomize** a few times at *Draft* quality, note the seed of
a result you like, then switch to *Production* and regenerate it. Same seed, same
furniture, more polygons.

```maxscript
-- Or drive it from script, bypassing the panel entirely:
local cfg = FurnGenConfig()
cfg = fgApplyStyle cfg #japandi
cfg.fabric = #linen
cfg.seed   = 481207
cfg.quality = 2

local bed = fgBuildItem cfg #bed #bedKing
```

## Catalogue

<table>
<tr><th align="left">Category</th><th align="left">Types</th></tr>
<tr>
<td><strong>Sofas</strong></td>
<td>straight · corner · modular · loveseat · chaise longue · armchair<br>
<em>optional styling: a throw draped over the armrest, two tilted accent pillows</em></td>
</tr>
<tr>
<td><strong>Beds</strong></td>
<td>single · double · king · four-poster<br>
<em>upholstered frame, mattress, headboard, draped duvet, pillows</em></td>
</tr>
<tr>
<td><strong>Chairs</strong></td>
<td>dining · bar · lounge · stool<br>
<em>rear legs continue into the backrest; the bar stool gets a foot ring</em></td>
</tr>
<tr>
<td><strong>Tables</strong></td>
<td>dining · coffee · side · desk · nightstand<br>
<em>aprons, drawer units, brass hardware</em></td>
</tr>
<tr>
<td><strong>Storage</strong></td>
<td>wardrobe · dresser<br>
<em>rail handles, three-drawer fronts, brass knobs</em></td>
</tr>
<tr>
<td><strong>Decor</strong></td>
<td>pouf · rug · floor lamp · bookshelf · TV console · plant · mirror<br>
<em>the bookshelf stacks randomised books; the plant grows unique stems</em></td>
</tr>
<tr>
<td><strong>Room sets</strong></td>
<td><strong>Living room</strong> — sofa, rug, coffee table, lounge chair, pouf, floor lamp, side table, bookshelf, plant<br>
<strong>Bedroom</strong> — bed, two nightstands, dresser, wardrobe, rug, bench, mirror, plant</td>
</tr>
</table>

## Styles

| Style | Character |
|---|---|
`#modern` | Squared arms, block legs, cool greys |
`#minimal` | No legs, no piping, off-white palette |
`#scandinavian` | Rounded arms, tapered light-oak legs |
`#japandi` | Low profile, muted earth tones, dark wood |
`#luxury` | Velvet, brass, deep jewel colours |
`#classic` | Wide rolled arms, piping, warm browns |
`#brutalism` | Floor-sitting, firm cushions, concrete greys |
`#midcentury` | Bolster arms, splayed walnut legs, ochre and teal |

## How the realism works

Every soft part runs through the same four-stage pipeline:

```
ChamferBox      base shape with a generous fillet
    ↓ Push      inflates along normals — the filling pressing outward
    ↓ Noise     fractal folds; a second finer pass adds wrinkles
    ↓ TurboSmooth   subdivision for a soft silhouette
```

Uniqueness comes from seeded jitter applied to positions, dimensions, tilts and
to the seed of every Noise modifier. Piping is a renderable spline traced around
the cushion perimeter, so the seam is real geometry rather than a texture.

Read more in [Architecture](docs/en/architecture.md).

## Materials

FurnGen never leaves a part grey. Material creation is a three-tier fallback:

1. **CoronaPhysicalMtl** — only when Corona is installed *and* is the active
   renderer. Corona materials render black or grey under other engines, so this
   is checked, not assumed.
2. **PhysicalMaterial** — for Scanline, Arnold and ART.
3. **StandardMaterial** — last resort, when no colour property accepted a write.

After every colour assignment the value is **read back and verified**. If the
write silently failed — which happens when Autodesk or Chaos renames a property
between versions — the material is downgraded and a `FurnGen MTL WARN` line is
printed to the Listener. Node wirecolor is driven from the material too, so
colour reads correctly even in Object Color viewport mode.

## Development

```bash
node tools/lint-maxscript.mjs     # lint all MAXScript sources
node tools/package-release.mjs    # build dist/FurnGen-<version>.zip
pnpm dev                          # run the documentation site
```

The linter is dependency-free and checks what actually breaks MAXScript:
unbalanced parentheses and brackets, `local` declared outside a scope, unknown
`fg*` helper calls resolved against the real module load order, missing
`FurnGenConfig` fields, unclamped `ChamferBox` fillets, and non-ASCII drift.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow and
[docs/en/extending.md](docs/en/extending.md) for adding a furniture type.

## Repository layout

```
src/
  FurnGen.ms          entry point — resolves and loads modules in order
  modules/
    core.ms           config struct, seeded RNG, style presets
    geometry.ms       soft blocks, cushions, armrests, legs, piping
    materials.ms      verified PBR material factory
    sofa.ms           sofa assembly
    furniture.ms      beds, chairs, tables, storage, decor, room sets
    qa.ms             post-build validation
    ui.ms             the panel
tools/
  lint-maxscript.mjs  static analysis for .ms sources
  package-release.mjs dependency-free zip builder
docs/en, docs/ru      documentation
app/, components/     documentation site (Next.js)
```

## Known limits

Procedural generation gets you convincing furniture, not simulated cloth. Folds
are noise-driven, so a duvet will not settle around a pillow the way a real cloth
solve would. For hero close-ups, generate at *Close-up* quality and finish the
drape with Cloth or Marvelous Designer.

## License

[MIT](LICENSE)
