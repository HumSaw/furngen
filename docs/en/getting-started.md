# Getting started

English &middot; [Русский](../ru/getting-started.md)

[← Documentation index](README.md)

## Requirements

| | |
|---|---|
| 3ds Max | 2020 or newer |
| Renderer | any — Corona is optional |
| System units | centimetres (recommended) |

FurnGen is pure MAXScript. There is nothing to compile, no plugin DLL, and no
external dependency at runtime.

## Installing

### From a release archive

1. Download `FurnGen-<version>.zip` from the [Releases](https://github.com/OWNER/furngen/releases) page.
2. Unzip it anywhere: your Max user-scripts folder, a network share, a project
   folder. Keep the `FurnGen` folder intact — the entry point resolves its
   modules relative to its own location, so moving `FurnGen.ms` away from
   `modules/` will break the load.
3. In 3ds Max: **Scripting → Run Script…**, pick `FurnGen.ms`, press **Open**.

The panel opens docked as a floating window.

### From source

```bash
git clone https://github.com/OWNER/furngen.git
cd furngen
node tools/package-release.mjs
```

This writes `dist/FurnGen-<version>.zip`. You can also run `src/FurnGen.ms`
directly from the clone — it works identically.

## Setting up the scene

FurnGen authors every dimension in centimetres. Match your scene to it:

**Customize → Units Setup → System Unit Scale → 1 Unit = 1.0 Centimeters**

This matters more than it sounds. Modifier amounts such as Push and Noise
strength are absolute values, not relative ones. In a scene set to inches, a
2 cm inflation becomes a 2 inch inflation and cushions balloon. The QA check
warns you when system units are not centimetres, but it cannot retroactively fix
geometry that was already built at the wrong scale.

## Your first item

Press **GENERATE**.

You get a three-seat modern sofa in bouclé, grouped, on its own scene layer,
with a validation report in the status line at the bottom of the panel.

Now try the loop that FurnGen is designed around:

1. Set **Quality** to *Draft*.
2. Press **Randomize** repeatedly. Each press rolls a new category-appropriate
   type, style, fabric and seed, then rebuilds.
3. When something looks right, write down the **Seed** value.
4. Set **Quality** to *Production*, type that seed back in, press **GENERATE**.

You get the same piece of furniture at render density. This works because every
random decision in the build derives from that one integer.

## A permanent toolbar button

Running a script from a file menu every session gets old. You do not need to do
anything to enable this: on a successful load, `FurnGen.ms` registers a macro
automatically.

Open **Customize → Customize User Interface → Toolbars**, choose the category
**FurnGen**, and drag **FurnGen** onto any toolbar. The button survives
restarts, and pressing it re-runs the loader from wherever you originally ran
it — so do not move the folder afterwards.

Registration is wrapped in a `try`, so if your Max configuration disallows it
the tool still loads normally and prints:

```
FurnGen: macro registration skipped (...)
```

## Where things end up

| What | Where |
|---|---|
| Generated geometry | grouped, on the scene layer `FurnGen_Furniture` |
| Presets you save | `FurnGen_Presets.ini` in your Max user-scripts folder |
| Diagnostics | MAXScript Listener, every line prefixed `FurnGen` |

Grouping means **Delete last** can remove a whole item cleanly, and the dedicated
layer means you can hide every generated piece without touching the rest of your
scene.

## Next steps

- [User guide](user-guide.md) — what each control does
- [Extending](extending.md) — add your own furniture type
- [Troubleshooting](troubleshooting.md) — when something looks wrong
