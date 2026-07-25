# Contributing to FurnGen

Thanks for wanting to help. New furniture types, style presets and fabrics are
especially welcome — the catalogue is the point of the project.

## Before you start

Read [docs/en/architecture.md](docs/en/architecture.md) for the module load order
and the determinism rules, then [docs/en/extending.md](docs/en/extending.md) for
worked examples. Both are short and will save you a review cycle.

## Setup

```bash
git clone https://github.com/OWNER/furngen.git
cd furngen
pnpm install          # only needed for the documentation site
```

The MAXScript tooling has no dependencies:

```bash
node tools/lint-maxscript.mjs      # lint all .ms sources
node tools/package-release.mjs     # build dist/FurnGen-<version>.zip
```

To test your changes, run `src/FurnGen.ms` in 3ds Max directly from your clone.
No packaging step is needed during development.

## The rules that matter

These are enforced by the linter or by review, and all of them exist because
breaking them produces geometry that looks *almost* right — the worst kind of bug.

| Rule | Reason |
|---|---|
| Centimetres everywhere | Push and Noise amounts are absolute values |
| Randomness only through `fgRandF` / `fgRandI` / `fgJitter` / `fgPick` | Seeds must stay reproducible |
| Never call `seed` inside a builder | Reseeding mid-build destroys determinism |
| Clamp every `ChamferBox` fillet with `amin` | Unclamped fillets fail silently |
| Name parts `FurnGen_<Item>_<Part>` | QA validates naming |
| Finish builders with `fgFinalizeItem` | Handles fallback materials, grouping, layering |
| Only call `fg*` helpers from modules loaded earlier | MAXScript has no imports; order is the contract |
| ASCII only in `.ms` files | Max's editor mangles non-ASCII on some locales |
| Index-aligned UI arrays must stay aligned | A mismatch silently builds the wrong item |

Run the linter before every commit. It catches most of the list above:

```bash
node tools/lint-maxscript.mjs
```

## Verifying your change

**MAXScript cannot be tested in CI.** There is no headless 3ds Max available to
us, so manual verification in Max is the actual test suite. Please do it properly
and record what you did in the pull request.

For any change that touches geometry or materials:

- [ ] `node tools/lint-maxscript.mjs` reports no errors
- [ ] The affected items generate without a Listener error
- [ ] The QA line shows no new warnings
- [ ] The same seed generated twice produces identical geometry
- [ ] Tested with Corona active **and** inactive — materials coloured in both
- [ ] Tested at Draft and Production quality
- [ ] Proportions read correctly against real furniture dimensions

Note your 3ds Max version, renderer(s) and the seeds you used. A screenshot is
required for geometry changes — proportions are the whole game here, and they are
much faster to judge from an image than from a diff.

## Commits

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(furniture): add bench to decor category
fix(materials): verify baseColor write on Max 2021
docs(en): document the softness pipeline
refactor(geometry): extract fillet clamping helper
chore(tools): make the packager dependency-free
```

Scopes match the module or area: `core`, `geometry`, `materials`, `sofa`,
`furniture`, `qa`, `ui`, `tools`, `docs`, `site`.

**Flag geometry-changing commits.** Because a build consumes random numbers in a
fixed order, inserting a random draw in the middle of a builder changes the output
of existing seeds. If your change does that, say so in the commit body — it needs
a changelog entry so users know their saved seeds will drift.

## Pull requests

1. Branch from `main`.
2. Keep it focused. One furniture type, or one fix, per PR.
3. Fill in the PR template, including the verification section and screenshots.
4. CI must pass: MAXScript lint, archive integrity, and the site build.

## Style

MAXScript, matching the existing code:

- Four-space indentation, `.ms` files (see `.editorconfig`)
- `fg` prefix on functions, `FurnGen_` prefix on globals and scene objects
- Lines under 120 characters
- A header comment on each module stating its purpose, dependencies and units
- Comment the *why*, not the *what* — especially for magic numbers. A constant
  like `0.45` in a fillet clamp needs a sentence explaining that ChamferBox fails
  above half the smallest dimension.

## Reporting bugs

Use the [issue templates](.github/ISSUE_TEMPLATE). The **seed** is the single
most useful field: every FurnGen result is reproducible from it, so with a seed we
see exactly what you saw.

## License

Contributions are made under the [MIT License](LICENSE).
