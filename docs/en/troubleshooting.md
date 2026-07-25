# Troubleshooting

[← Documentation index](README.md)

Open the MAXScript Listener with **F11** first. Every FurnGen diagnostic is
prefixed `FurnGen`, so it is easy to find among Max's own output.

## The script will not run

**"Unable to find include file" or a module load error**

`FurnGen.ms` locates `modules/` relative to its own path. If you copied
`FurnGen.ms` somewhere without the `modules` folder, it cannot find its code.
Keep the folder intact:

```
FurnGen/
  FurnGen.ms
  modules/
    core.ms
    ...
```

**Nothing happens when the script runs**

Check the Listener for a syntax error. If you edited a `.ms` file, run the linter
— an unbalanced parenthesis is the most common cause and MAXScript reports it
unhelpfully:

```bash
node tools/lint-maxscript.mjs
```

**The panel opened before, but not now**

A previous floater may still be registered. In the Listener:

```maxscript
try (closeRolloutFloater FurnGenUI_Floater) catch ()
fgOpenUI()
```

## Everything is grey

Almost always a renderer or property-name mismatch, and FurnGen tells you when it
happens. Look for:

```
FurnGen MTL WARN: ...
```

That line means a colour write was rejected and verified as failed, so the
material was downgraded. Report it as a bug with your 3ds Max version — the
property name likely changed in a release we have not covered yet.

**If there is no warning but the render is still grey:**

- **Corona materials under a different renderer.** FurnGen only builds Corona
  materials when Corona is installed *and* active. If you generated with Corona
  active, then switched renderer, regenerate the item.
- **Viewport is in Object Color mode.** Wirecolor is set from the material, so
  colour should still read — but shading will look flat. Switch the viewport to
  Realistic or Shaded.

## Furniture is the wrong size

Check **Customize → Units Setup → System Unit Scale**. It should be
**Centimeters**.

This is the single most common cause of strange output. Push and Noise amounts
are absolute values. In a scene set to inches, a 2 cm inflation becomes a 2 inch
inflation and cushions balloon into blobs; in millimetres they barely move and
the furniture looks like hard plastic.

The QA report warns about this:

```
FurnGen QA WARN: system units = Inches (expected Centimeters)
```

Fix the units, then **regenerate**. Changing units afterwards rescales the scene
but does not undo the distorted modifier results.

## Cushions look like balloons

Lower **Softness**. Above roughly 0.8 the Push amount can overwhelm small
cushions, especially on narrow types like a loveseat or armchair. Values from 0.3
to 0.6 cover most real furniture.

## Cushions look like hard foam

Raise **Softness**, and check you are not on a style that deliberately firms
things up — Brutalism forces `cushionSoftness` to 0.35 by design.

## Piping is missing

Three things can switch it off, in this order:

1. The **Piping seams** checkbox.
2. The style: Minimal and Brutalism both set `piping = false`.
3. The category: piping only applies to soft furniture — sofas, beds and chairs.

The panel combines the checkbox with the style using `and`, so a style that
disables piping wins over the checkbox.

## The same seed gives different results

It should not. Verify that *every* other setting matches — category, type, style,
fabric, seat count, all dimensions, softness, the three checkboxes and quality.
Quality changes segment counts and TurboSmooth iterations, so the same seed at
Draft and at Close-up produces the same *shape* at different densities, which can
look different at a glance.

If everything genuinely matches and results still differ, that is a bug. Please
[open an issue](../../../issues) with both seeds and your Max version.

## Geometry warnings from QA

```
FurnGen QA WARN: degenerate geometry in FurnGen_Sofa_Cushion_2
```

A part collapsed to zero extent. This usually means an extreme dimension
combination — a very narrow width with a high seat count, for example. Try
adjusting dimensions, and please report it with the seed and settings, since QA
catching it means we can reproduce it exactly.

## Room sets overlap or float

Room sets place items on a fixed coordinate plan sized for a typical room. A very
wide sofa can push into the side table. Generate the set, then move individual
pieces — each is its own group, so they are easy to reposition.

## Performance

**Generation is slow**

Use *Draft* while exploring. Close-up 4K adds a second Noise pass and higher
TurboSmooth iterations to every soft part, which multiplies quickly across a room
set of nine items.

**The scene becomes heavy**

- Generate props in Draft and only hero furniture in Production or Close-up.
- Every item lives on the `FurnGen_Furniture` layer — hide it while you work.
- Use **Delete last** to clean up while iterating instead of accumulating
  discarded geometry.

## Reporting a bug

Please include:

1. FurnGen version — shown in the panel title bar
2. 3ds Max version and active renderer
3. Category, type, style, fabric, quality and **seed**
4. The Listener output, filtered to `FurnGen` lines
5. A screenshot for anything visual

The seed matters most. With it we can reproduce your exact result; without it we
are guessing.

[Open an issue →](../../../issues/new/choose)
