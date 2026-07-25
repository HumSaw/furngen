# Extending FurnGen

[← Documentation index](README.md)

Read [Architecture](architecture.md) first — particularly the module load order,
since it constrains where new code can go.

## Conventions

Follow these and your addition will behave like the rest of the tool.

| Rule | Why |
|---|---|
| Centimetres, always | Push and Noise amounts are absolute; mixed units warp geometry |
| Randomness only via `fgRandF` / `fgRandI` / `fgJitter` / `fgPick` | Keeps seeds reproducible |
| Never call `seed` yourself | Reseeding mid-build breaks determinism |
| Name parts `FurnGen_<Item>_<Part>` | QA checks naming; the scene stays searchable |
| End the builder with `fgFinalizeItem` | Handles fallback materials, grouping and layering |
| Clamp every `ChamferBox` fillet with `amin` | Unclamped fillets fail silently |
| ASCII only in `.ms` files | Max's script editor mangles non-ASCII on some locales |
| Prefix diagnostics with `FurnGen` | Makes Listener output filterable |

Run the linter before you commit — it checks most of the above:

```bash
node tools/lint-maxscript.mjs
```

## Adding a style preset

The cheapest useful contribution. Open `src/modules/core.ms`, find
`fgApplyStyle`, and add a case:

```maxscript
#industrial:
(
    cfg.armStyle = #square; cfg.legStyle = #cylinder
    cfg.legHeight = 14.0; cfg.armWidth = 24.0; cfg.armHeight = 58.0
    cfg.fabric = #leather
    cfg.fabricColor = fgPick #(color 78 66 58, color 96 88 80, color 58 54 52)
    cfg.legColor = color 74 74 78      -- blackened steel
)
```

Then register it in `src/modules/ui.ms` — the arrays are index-aligned, so add to
**both** at the same position:

```maxscript
global FurnGen_StyleKeys = #(#modern, ..., #midcentury, #industrial)
```

```maxscript
dropdownlist ddStyle "Style:" items:#("Modern", ..., "Mid-century", "Industrial")
```

A style may override `fabric`, `piping`, `height` or `cushionSoftness`. Do it
deliberately — the preset represents a coherent design language, and users see
it as the style "winning" over their earlier choice.

## Adding a fabric

In `src/modules/materials.ms`, extend `fgFabricParams`:

```maxscript
#corduroy: #(0.72, 0.0, 0.10, 3.2)   -- roughness, metalness, sheen, bumpAmount
```

and give it a bump character in `fgFabricBumpMap`. Corduroy wants directional
ribs, so a stretched Noise rather than an isotropic one. Then add the key and
label to `FurnGen_FabricKeys` and the `ddFabric` items — index-aligned, as above.

## Adding a furniture type

Worked example: a **bench** in the Decor category.

### 1. Write the builder

Add a case to `fgBuildDecor` in `src/modules/furniture.ms`:

```maxscript
#bench:
(
    local w = fgJitter 120.0 10.0        -- vary the size a little
    local d = 38.0
    local h = 45.0
    local legMtl = fgMakeLegMtl cfg
    local seatMtl = fgMakeFabricMtl cfg

    -- Upholstered top: soft block, not a plain box
    local top = fgSoftBlock w d 9.0 3.0 cfg "FurnGen_Bench_Seat" \
                    softness:(cfg.cushionSoftness * 0.5)
    top.pos = [0, 0, h]
    top.material = seatMtl
    append parts top

    -- Four legs, slightly splayed
    fgFourLegs parts w d h legMtl "FurnGen_Bench" inset:7.0 splay:1.5

    if cfg.piping then
    (
        local pipe = fgPiping w d 3.0 0.5 "FurnGen_Bench_Piping"
        pipe.pos = [0, 0, h + 4.5]
        pipe.material = fgMakePipingMtl cfg seatMtl
        append parts pipe
    )
)
```

Notes on why this is written the way it is:

- `fgSoftBlock` rather than `Box`, so the seat reads as upholstered.
- Softness is halved — a bench seat is firmer than a sofa cushion.
- `fgJitter` on width so repeated generations differ.
- `fgFourLegs` handles inset, splay, naming and material for all four legs.
- Piping is gated on `cfg.piping`, respecting the user's checkbox and the style.

### 2. Register it in the panel

`src/modules/ui.ms`, Decor is category index 6:

```maxscript
#(#pouf, #rug, #floorLamp, #bookshelf, #tvConsole, #plant, #mirror, #bench)
```

```maxscript
#("Pouf", "Rug", "Floor lamp", "Bookshelf", "TV console", "Plant", "Mirror", "Bench")
```

Both arrays must stay index-aligned or the panel will build the wrong item — a
silent, confusing failure.

### 3. Verify

```bash
node tools/lint-maxscript.mjs
```

Then in 3ds Max:

- Generate the bench. Does it read as a bench at real scale?
- Generate the same seed twice. Identical geometry?
- Check the QA line. No new warnings?
- Toggle piping and softness. Do they visibly do something?
- Test with Corona active **and** inactive. Coloured in both?

## Adding a category

More involved, because five index-aligned arrays must agree.

1. Write `fgBuildLighting cfg itemType` in `furniture.ms`, following the shape of
   the existing builders and ending with `fgFinalizeItem`.
2. Add a branch to `fgBuildItem`.
3. Append to `FurnGen_Categories`, `FurnGen_CatLabels`, `FurnGen_TypeKeys` and
   `FurnGen_TypeLabels` — same index in all four.
4. Update `syncEnabled` so the upholstery and dimension controls grey out
   appropriately for the new category. Users read greyed controls as "this
   parameter does nothing here", so getting this right matters.

## Adding a room set

Copy `fgBuildRoomSet` as a template. The important details:

- Build one `cfg`, apply one style, and share it across every item so the room is
  coordinated.
- Give item *n* the seed `baseSeed + n`, so the room reproduces from one seed
  while individual pieces differ.
- Place items on a coordinate plan in centimetres, and pick one wall direction as
  the convention (the bedroom set assumes the headboard faces +Y).
- Return the outer group.

## Submitting

See [CONTRIBUTING.md](../../CONTRIBUTING.md). Geometry changes need a screenshot
and the seeds you tested, because MAXScript cannot be exercised in CI — manual
verification in Max is the only real test we have.
