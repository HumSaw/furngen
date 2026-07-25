# Changelog

All notable changes to FurnGen are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
the project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **Note on seeds.** A build consumes random numbers in a fixed order, so any
> change that adds or removes a random draw inside a builder shifts the output of
> existing seeds. Releases that do this are marked **[changes geometry]**, because
> saved presets will produce different — not broken — furniture afterwards.

## [Unreleased]

Nothing yet.

## [1.0.0] — 2026-07-25

First public release.

### Added

**Furniture catalogue** — 28 types across six categories, all authored at
real-world scale in centimetres.

- Sofas: straight, corner, modular, loveseat, chaise lounge, armchair
- Beds: single, double, king, canopy — upholstered frame, mattress, headboard,
  draped duvet and pillows
- Chairs: dining, bar stool, lounge, stool — rear legs continue into the
  backrest; the bar stool gets a foot ring
- Tables: dining, coffee, side, desk, nightstand — aprons, drawer units, brass
  hardware
- Storage: wardrobe, dresser — rail handles, three-drawer fronts, brass knobs
- Decor: pouf, rug, floor lamp, bookshelf, TV console, plant, mirror — the
  bookshelf stacks randomised books, the plant grows unique stems

**Room sets** — one-click coordinated interiors sharing a style and palette.

- Living room: sofa, rug, coffee table, lounge chair, pouf, floor lamp, side
  table, bookshelf, plant
- Bedroom: bed, two nightstands, dresser, wardrobe, rug, bench, mirror, plant
- Each item receives `baseSeed + n`, so a room is reproducible from one seed
  while no two pieces are identical

**Style system** — eight presets, each rewriting proportions, armrest shape, leg
type, leg height and palette together: modern, minimal, scandinavian, japandi,
luxury, classic, brutalism, mid-century.

**Fabrics** — bouclé, velvet, linen, cotton and leather, each with its own
roughness, sheen and procedural bump. No bitmap dependencies, so moving the
archive never breaks a material.

**Softness pipeline** — the four-stage stack behind every upholstered part:
ChamferBox → Push → fractal Noise → TurboSmooth. A single Softness parameter
drives both inflation and fold depth. Piping is a renderable spline traced around
the cushion perimeter, so seams are real geometry that catches a highlight.

**Renderer-agnostic materials** — Corona materials are built only when Corona is
installed *and* is the active renderer, since Corona materials render grey
elsewhere. Otherwise `PhysicalMaterial` is used, covering Scanline, Arnold and
ART. Every colour write is read back and verified; a failed write downgrades the
material and prints a `FurnGen MTL WARN` line rather than shipping grey furniture
silently. Node wirecolor is driven from the material, so colour reads correctly
in Object Color viewport mode too.

**Reproducibility** — every random decision derives from one integer seed. The
seed is applied before the style pass so palette picks are deterministic as well.

**Quality levels** — Draft, Production and Close-up 4K, controlling segment
counts, TurboSmooth iterations and whether the fine wrinkle pass runs.

**QA validation** — after every build, items are checked for system units,
plausible bounding box, materials on every part, degenerate geometry and naming
convention. The summary appears in the panel status line, the detail in the
Listener. QA reports; it never blocks a build.

**Panel** — category → type → style → fabric, with controls that grey out when
they do not apply to the current category. Randomize, Surprise me, both room-set
buttons, Delete last, and INI-backed presets saved to the Max user-scripts folder.

**Safety** — builds run inside an undo block; a failure rolls back partial
geometry instead of leaving debris in the scene, and reports the exception to both
the status line and the Listener. Generated items are grouped and placed on a
dedicated `FurnGen_Furniture` layer.

**Toolbar integration** — `FurnGenRegisterMacro()` registers a macroscript so the
panel can be dragged onto a toolbar and survives restarts.

### Tooling

- `tools/lint-maxscript.mjs` — dependency-free static analysis for MAXScript:
  unbalanced parentheses and brackets, `local` outside a scope, unknown `fg*`
  helper calls resolved against the real module load order, missing
  `FurnGenConfig` fields, unclamped `ChamferBox` fillets and non-ASCII drift
- `tools/package-release.mjs` — builds the distributable archive with a ZIP writer
  implemented on Node's `zlib`, so no `zip` binary is required and the output is
  identical on a developer machine and in CI
- GitHub Actions CI running the linter, verifying archive integrity, and building
  the documentation site
- Issue and pull-request templates that ask for the seed, since every result is
  reproducible from it

### Documentation

- Full English and Russian documentation: getting started, user guide,
  architecture, extending guide and troubleshooting
- Contributing guide with the manual verification checklist that stands in for
  automated tests, since MAXScript cannot be exercised in CI

### Requirements

3ds Max 2020 or newer. Corona Renderer optional. System units set to centimetres
is strongly recommended and checked by QA.

[Unreleased]: https://github.com/OWNER/furngen/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/OWNER/furngen/releases/tag/v1.0.0
