# Architecture

[← Documentation index](README.md)

How FurnGen is put together, and why it is built this way.

## Module graph

MAXScript has no import system. `FurnGen.ms` resolves its own directory and
`filein`s each module in dependency order, so a module may only call helpers
declared in modules loaded before it.

```
FurnGen.ms                    entry point, path resolution, load order
  │
  ├── core.ms                 (no dependencies)
  │     config struct · seeded RNG · style presets · layer helper
  │
  ├── geometry.ms             → core
  │     soft blocks · cushions · armrests · legs · piping splines
  │
  ├── materials.ms            → core
  │     renderer detection · verified PBR factory · fabric definitions
  │
  ├── sofa.ms                 → core, geometry, materials
  │     run-based sofa assembly (straight, corner, modular, chaise…)
  │
  ├── furniture.ms            → core, geometry, materials
  │     beds · chairs · tables · storage · decor · room sets · dispatcher
  │
  ├── qa.ms                   → core
  │     post-build validation
  │
  └── ui.ms                   → everything above
        the panel
```

The linter enforces this: calling an `fg*` helper that is not declared in the
current module or an earlier one is a lint error, which catches load-order bugs
statically instead of at runtime in front of a user.

## Determinism

Reproducibility is the property everything else is designed around. If a user
can send you a seed, you can see exactly what they saw.

MAXScript's `seed` sets one global RNG stream. Every random value in FurnGen
comes from that stream through four helpers:

```maxscript
fgRandF a b      -- float in range
fgRandI a b      -- integer in range
fgJitter v amt   -- v ± amt, for organic asymmetry
fgPick arr       -- one element of an array
```

Two rules keep this intact:

1. **`fgSetSeed` is called once, before the style pass.** The style preset picks
   its palette with `fgPick`, so it must draw from the already-seeded stream —
   otherwise colour would not be reproducible.
2. **Nothing else reseeds mid-build.** Noise modifiers get an explicit
   `fgRandI 1 99999` seed drawn from the same stream, so folds vary between parts
   yet stay reproducible as a set.

Because a build consumes random numbers in a fixed order, inserting a new
`fgRandF` call in the middle of a builder shifts every subsequent draw and
changes the output for existing seeds. That is expected, and it is why the
changelog flags releases that alter generated geometry.

## The softness pipeline

Every upholstered part is built by the same four-stage stack. This is the core
technique of the whole tool.

```
1. ChamferBox        base volume with a generous fillet
                     — a hard-edged box never reads as upholstery
2. Push              inflates along vertex normals
                     — simulates filling pressing against the cover
3. Noise (fractal)   large-scale sag and folds
                     — a second, finer pass adds wrinkles when quality >= 2
4. TurboSmooth       subdivision into a soft silhouette
```

Implemented in `fgSoftBlock` and `fgCushion`:

```maxscript
fn fgSoftBlock w d h fillet cfg partName softness:0.25
fn fgCushion   w d h cfg partName isBack:false
```

Push and Noise amounts scale with `cfg.cushionSoftness`, which is why one
spinner changes the entire character of a piece.

### Why the fillet is clamped

`ChamferBox` fails silently — or produces inverted geometry — when the fillet
exceeds half of the smallest dimension. Every fillet is therefore clamped:

```maxscript
local maxFillet = (amin (amin w d) h) * 0.45
if fillet > maxFillet then fillet = maxFillet
```

The linter flags any `ChamferBox` whose `fillet:` is a bare literal without an
`amin` clamp nearby, because this failure is easy to introduce and produces
geometry that looks *almost* right.

### Piping

Seams are real geometry, not a texture: a spline traced around the cushion
perimeter with `renderable = true` and a small `thickness`. At close range a
modelled seam catches a specular highlight the way a normal map cannot.

```maxscript
fn fgPiping w d cornerR pipeR partName
```

## Materials

### Renderer detection

Corona materials render black or grey under other engines, so FurnGen never
assumes:

```maxscript
fn fgCoronaAvailable = ((classof CoronaPhysicalMtl == material) or (classof CoronaMtl == material))
fn fgRendererIsCorona                      -- inspects the active renderer
fn fgUseCorona = (fgCoronaAvailable() and fgRendererIsCorona())
```

Corona materials are only built when Corona is **installed and active**.
Otherwise the tool builds `PhysicalMaterial`, which renders correctly in
Scanline, Arnold and ART.

### Verified colour assignment

Autodesk and Chaos rename material properties between versions. Writing
`baseColor` on a version that expects `base_color` fails silently and leaves a
grey material — which the artist only discovers at render time.

So every write is read back:

```maxscript
fn fgVerifiedSetColor m propNames col   -- try each name, then verify by reading
```

If no candidate name took the colour, the material is downgraded to
`StandardMaterial` and a `FurnGen MTL WARN` line is printed. The tool degrades
loudly instead of shipping grey furniture quietly.

Node `wirecolor` is driven from the final material colour too, so items read
correctly even in Object Color viewport mode.

### Fabric definitions

`fgFabricParams` returns five values per fabric:

```maxscript
#(roughness, sheenAmount, bumpSize, bumpStrength, useCellular)
```

`fgFabricBumpMap` reads that tuple and builds the matching procedural map:
`Cellular` when `useCellular` is true (leather pores), otherwise fractal `Noise`
sized by `bumpSize` — coarse for bouclé, fine for velvet. Everything is
procedural, so there are no bitmap dependencies to break when the archive moves.

## Sofa assembly: runs

A sofa is composed of **runs** — straight segments with an origin, a rotation and
independently controlled armrests:

```maxscript
fn fgBuildRun cfg runWidth runDepth origin rotZ parts prefix \
              withLeftArm withRightArm fabricMtl pipingMtl
```

Every sofa type is a different arrangement of runs:

| Type | Composition |
|---|---|
| Straight | one run, both arms |
| Loveseat | one narrow run, both arms |
| Armchair | one 100 cm run, both arms |
| Corner | main run with left arm + perpendicular run rotated 90°, right arm |
| Chaise | main run + armless extension, plus a raised chaise platform |
| Modular | several runs, arms only on the outer ends |

Adding a new sofa layout means describing its runs, not writing new geometry.

## Item dispatch

One entry point routes to the right builder:

```maxscript
fn fgBuildItem cfg category itemType
```

`category` is one of `#sofa #bed #chair #table #storage #decor`, and `itemType`
is a key from that category. Every builder returns the finished group node.

```maxscript
fgBuildSofa    cfg
fgBuildBed     cfg itemType
fgBuildChair   cfg itemType
fgBuildTable   cfg itemType
fgBuildStorage cfg itemType
fgBuildDecor   cfg itemType
```

`fgFinalizeItem parts grpName defaultMtl` closes out every build: it assigns a
fallback material to anything still unshaded, groups the parts, moves the group
to the `FurnGen_Furniture` layer and returns it. Because every builder ends here,
no builder can forget to do the bookkeeping.

## Room sets

`fgBuildRoomSet` and `fgBuildBedroomSet` place items on a coordinate plan while
sharing one style. Each item receives `baseSeed + n`, so the room as a whole is
reproducible from a single seed and no two pieces are identical.

## QA

After every build, `fgValidateItem grp` walks the group and checks:

- **System units** are centimetres, since modifier amounts are absolute
- **Bounding box** falls inside plausible furniture dimensions (20–650 cm wide,
  1–260 cm tall, spanning a side table up to a canopy bed or a whole room set)
- **Every part has a material**
- **No empty geometry** — parts whose mesh has zero verts or faces
- **No leftover default names** like `Box001` or `ChamferBox001`

The walk is recursive (`fgCollectParts`), so it also covers child nodes such as
the bolster parented to a `#pillow` armrest, and nested groups inside a room set.

It returns an **array of report lines**, and the summary is always the last
element — which is why the panel can read `report[report.count]` for the status
line while every line goes to the Listener:

```
OK: 34 parts / 118240 tris, render ready
CHECKED: 34 parts / 118240 tris, 2 issue(s) - see Listener
```

QA never blocks a build. It tells you what to look at.

## Error handling

`doGenerate` wraps the build in an undo block:

```maxscript
try ( undo "FurnGen Generate" on ( grp = fgBuildItem cfg category itemType ) )
catch ( reportFailure(); return() )
```

On failure `reportFailure` calls `max undo`, so a half-built item is rolled back
instead of leaving orphaned geometry in the scene, and the exception text goes to
both the status line and the Listener.

## Extending

See [Extending FurnGen](extending.md) for a worked example of adding a new
furniture type.
