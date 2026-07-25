# FurnGen documentation

English · [Русский](../ru/README.md)

## For artists

**[Getting started](getting-started.md)**
Requirements, installation, scene setup, your first generated item, and adding a
permanent toolbar button.

**[User guide](user-guide.md)**
Every control in the panel and what it actually changes — styles, fabrics,
softness, quality, seeds, room sets and presets. Includes how to read the QA
report.

**[Troubleshooting](troubleshooting.md)**
Grey materials, wrong scale, balloon cushions, missing piping, non-reproducible
seeds, and what to include in a bug report.

## For developers

**[Architecture](architecture.md)**
The module graph and load order, how determinism is preserved, the four-stage
softness pipeline, verified material assignment, run-based sofa assembly, and the
QA layer.

**[Extending FurnGen](extending.md)**
Conventions, then worked examples: adding a style preset, a fabric, a furniture
type, a whole category, and a room set.

**[Contributing](../../CONTRIBUTING.md)**
Workflow, commit format, and the manual verification checklist that stands in for
automated tests.

## Reference

| | |
|---|---|
| [Changelog](../../CHANGELOG.md) | Release history, including which releases change generated geometry |
| [Security policy](../../SECURITY.md) | How to report a vulnerability |
| [License](../../LICENSE) | MIT |

## Quick answers

**What units does FurnGen use?**
Centimetres. Set **Customize → Units Setup → System Unit Scale = Centimeters**
before generating. See [getting started](getting-started.md#setting-up-the-scene).

**Do I need Corona?**
No. Corona materials are built only when Corona is installed *and* active;
otherwise you get `PhysicalMaterial`, which works in Scanline, Arnold and ART.

**How do I reproduce a result exactly?**
Note its seed and keep every other setting the same. See
[seeds](user-guide.md#seed).

**Why are some controls greyed out?**
They do not apply to the selected category. Dimension spinners are sofa-only
because a king-size bed has defined dimensions by convention.

**Can I use it without the panel?**
Yes — the panel is a thin layer over `fgBuildItem`. See
[scripting it](user-guide.md#scripting-it).
