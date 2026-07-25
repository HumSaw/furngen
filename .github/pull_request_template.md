# Summary

<!-- What does this change and why? One paragraph is plenty. -->

## Type of change

- [ ] New furniture type or category
- [ ] New style, fabric or material
- [ ] Bug fix
- [ ] Refactor with no behaviour change
- [ ] Documentation
- [ ] Tooling or CI

## Verification

<!--
MAXScript cannot be unit tested in CI, so manual verification in 3ds Max
is the contract for every geometry change. Please fill this in honestly.
-->

- [ ] `node tools/lint-maxscript.mjs` passes with no errors
- [ ] Ran in 3ds Max and generated the affected item(s)
- [ ] Checked the QA report in the panel status line, no new warnings
- [ ] Tested the same seed twice and got identical geometry
- [ ] Tested with Corona active **and** with Corona inactive, materials visible in both

**3ds Max version tested:**
**Renderer(s) tested:**
**Seeds tested:**

## Screenshots

<!-- Before and after, or a render of the new item. Required for geometry changes. -->

## Notes for reviewers

<!-- Anything non-obvious: coordinate conventions, why a magic number, known limits. -->
