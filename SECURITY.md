# Security policy

## Supported versions

| Version | Supported |
| --- | --- |
| 1.0.x | Yes |
| < 1.0 | No |

## Reporting a vulnerability

Please **do not** open a public issue for a security problem.

Use GitHub's private reporting instead: go to the repository's **Security** tab
and choose **Report a vulnerability**. If that is unavailable, contact the
maintainers listed in `package.json`.

Include where practical:

- the affected file and function
- a minimal reproduction (script parameters or a `.max` file)
- what an attacker could achieve
- the 3ds Max version and active renderer

You can expect an initial response within a week.

## Threat model

FurnGen is a MAXScript tool that runs inside 3ds Max with the full privileges of
the host application. It is worth being explicit about what that means:

**In scope**

- Arbitrary code execution triggered by loading or running FurnGen itself
- Path traversal or unintended file writes outside the preset location
  (`getDir #userScripts`)
- Unvalidated data read from a preset INI being executed rather than parsed

**Out of scope**

- Vulnerabilities in 3ds Max, Corona Renderer, or other plugins — report those to
  their vendors
- The fact that MAXScript can access the filesystem by design
- Running a modified copy of FurnGen that you obtained from an untrusted source

## Notes for users

- Only run FurnGen from a source you trust. MAXScript has no sandbox: any `.ms`
  file you execute can read and write files and reach the network.
- Preset files are plain INI written by FurnGen. Values are parsed with explicit
  `as integer` / `as float` conversions and are never evaluated as code, so a
  hand-edited preset cannot inject script — but a malformed one may produce
  odd geometry.
- Release archives are built by `tools/package-release.mjs` in CI. Prefer the
  published archive over a copy forwarded by a third party.
