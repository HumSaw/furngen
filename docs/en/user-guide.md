# User guide

[← Documentation index](README.md)

Every control in the panel, and what it actually changes.

## What to build

### Category

Six families: **Sofas, Beds, Chairs, Tables, Storage, Decor**. Changing the
category repopulates the **Type** list and enables or greys out the controls
below, so the panel always shows only parameters that do something.

### Type

The specific piece. Twenty-eight in total — see the
[catalogue in the README](../../README.md#catalogue).

### Style

Eight presets. A style is not a colour swatch: it rewrites proportions, armrest
shape, leg type, leg height and palette all at once, and some styles override
other settings deliberately.

| Style | Arms | Legs | Palette | Overrides |
|---|---|---|---|---|
| Modern | square | block, 8 cm | cool greys | — |
| Minimal | square | none, 4 cm | off-whites | piping off |
| Scandinavian | rounded | cone, 16 cm | light neutrals, sage | — |
| Japandi | square | block, 10 cm | muted earth | height → 74 cm |
| Luxury | rounded | cylinder, 10 cm | jewel tones, brass | fabric → velvet |
| Classic | rounded | cone, 12 cm | warm browns | piping on |
| Brutalism | square | none, 2 cm | concrete greys | piping off, softness → 0.35 |
| Mid-century | bolster | cone, 18 cm | ochre, teal, walnut | — |

Because Luxury forces velvet and Minimal forces piping off, changing the style
can visibly override a choice you made further down the panel. That is
intentional — the preset represents a coherent design language.

### Fabric

Five upholstery materials, each with its own roughness, sheen and bump
character:

| Fabric | Look | Bump source |
|---|---|---|
| Bouclé | matte, nubby loops | coarse fractal noise |
| Velvet | soft sheen, directional | fine noise plus high sheen |
| Linen | dry, visible weave | medium fractal noise |
| Cotton | soft, neutral | fine weave noise |
| Leather | low roughness, pore grain | cellular noise |

## Dimensions

**Sofas only.** Beds, chairs, tables, storage and decor derive their dimensions
from their type, because a king-size bed is 180 × 200 cm by definition — letting
a generic width spinner stretch it produces nonsense. These spinners grey out
automatically outside the Sofas category.

| Control | Range | Notes |
|---|---|---|
| Seats | 1–6 | Drives minimum width: `seats × 65 + arms` |
| Width | 40–500 cm | Raised automatically if too narrow for the seat count |
| Depth | 30–220 cm | 95–105 cm is the realistic range |
| Height | 30–250 cm | Total back height from the floor |

Loveseat and armchair types set their own width (170 cm and 100 cm) and ignore
the spinner.

## Upholstery

### Softness (0.0–1.0)

The single most expressive control. It scales both the Push amount — how much
the filling inflates against the cover — and the Noise strength that creates
folds.

| Value | Result |
|---|---|
| 0.0–0.2 | Firm, architectural, foam-block furniture |
| 0.3–0.5 | Tailored; most commercial furniture lives here |
| 0.6–0.8 | Relaxed, generous, down-filled |
| 0.9–1.0 | Very slouchy; verify the silhouette still reads |

### Piping seams

Adds a renderable spline traced around each cushion perimeter, shaded in a
darker tint of the fabric. It is real geometry, so it catches a highlight and
reads at close range where a texture would not. Costs a few thousand polygons
per cushion.

### Back cushions

**Sofas only.** Separate loose cushions leaning against the backrest, each with
its own seeded tilt. Turn it off for a tight-back sofa.

### Styling

**Sofas only.** Adds a throw blanket draped over the right armrest — bent,
noise-folded and subdivided — plus two accent pillows in a contrasting colour,
tilted off-axis. Turn it off when the sofa is a background prop.

## Generate

### Quality

Controls segment counts, TurboSmooth iterations and whether the fine wrinkle
pass runs at all.

| Level | Use for | Cost |
|---|---|---|
| Draft | Exploring, layout blocking | lightest |
| Production | Normal renders | balanced |
| Close-up 4K | Hero shots filling the frame | heaviest |

Explore in Draft, render in Production. Reach for Close-up only when the
furniture dominates the frame — the fine wrinkle pass is invisible at distance
and simply costs memory.

### Seed

An integer from 1 to 999999 that determines every random decision in the build:
cushion tilts, fold patterns, palette picks within the style, book placement on
a shelf, stem angles on a plant.

**The same seed with the same settings always produces identical geometry.** This
is the core workflow guarantee. Note the seed of anything you like — it is the
only thing you need to reproduce it exactly.

### GENERATE

Builds the item, groups it, puts it on the `FurnGen_Furniture` layer, runs QA and
selects it. If the build throws, the partial geometry is rolled back through undo
and the error appears in the status line rather than leaving debris in your scene.

### Randomize

Rolls a new type, style, fabric, seat count, dimensions, softness and seed
*within the current category*, then generates. This is the exploration loop.

### Surprise me

The same, but it also rolls the category. Use it when you have no particular
brief and want to see what the generator suggests.

### BUILD LIVING ROOM

One click, nine coordinated pieces sharing a style and palette: sofa, rug,
coffee table, lounge chair, pouf, floor lamp, side table, bookshelf, plant. Each
piece gets `baseSeed + n`, so the room is reproducible as a whole while no two
pieces are identical.

### BUILD BEDROOM

Eight pieces: bed, two nightstands, dresser, wardrobe, rug, bench, mirror, plant.
The bed's headboard faces +Y, so the room assumes a wall behind it.

### Delete last

Deletes the most recently generated group, undoably. Handy for hammering
**Randomize** without burying the scene.

## Presets

Type a name, press **Save**. Everything in the panel — category, type, style,
fabric, dimensions, softness, seed and quality — is written to
`FurnGen_Presets.ini` in your Max user-scripts folder. **Load** restores it.

Presets survive Max restarts and can be shared with a team by copying the INI.

## Reading the QA report

The status line shows the summary. Press **F11** for the full report in the
Listener.

| Message | Meaning |
|---|---|
| `OK: N parts, no problems found` | Clean build |
| `WARN: system units = ...` | Scene is not in centimetres — fix Units Setup |
| `WARN: suspicious width/height` | Result fell outside plausible furniture bounds |
| `WARN: N part(s) without material` | Report this as a bug with your seed |
| `WARN: degenerate geometry` | A part collapsed; report it with your seed |
| `Error: ...` | Build failed and was rolled back; check the Listener |

## Scripting it

The panel is a thin layer over the API. Everything is reachable from script:

```maxscript
local cfg = FurnGenConfig()          -- defaults
cfg = fgApplyStyle cfg #midcentury   -- proportions + palette
cfg.fabric  = #leather
cfg.quality = 2
cfg.seed    = 90210

-- Any category and type, dispatched through one entry point
local chair = fgBuildItem cfg #chair #chairLounge

-- Batch a variant sheet for client review
for i = 1 to 5 do
(
    cfg.seed = 1000 * i
    local item = fgBuildItem cfg #sofa #straight
    item.pos = [i * 300, 0, 0]
)
```

See [Architecture](architecture.md) for the full API surface.
