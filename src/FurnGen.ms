/*
    FurnGen.ms -- entry point
    ========================
    FurnGen: a procedural furniture generator for Autodesk 3ds Max.
    Builds render-ready sofas, beds, chairs, tables, storage, decor
    and complete room sets with a single click.

    Usage:
        3ds Max > Scripting > Run Script... > src/FurnGen.ms

    Requirements:
        - 3ds Max 2020 or newer
        - Corona Renderer (optional; falls back to Physical Material)
        - System Units set to Centimeters (recommended)

    Repository: https://github.com/HumSaw/furngen
    License: MIT
*/

(
    local rootDir = getFilenamePath (getThisScriptFilename())
    local moduleDir = rootDir + "modules\\"

    -- Load order matters: every module may only depend on the ones above it.
    local modules = #(
        "core.ms",       -- config struct, RNG, style presets, utilities
        "geometry.ms",   -- low-level soft-body / cushion / piping primitives
        "materials.ms",  -- PBR material factory (Corona + Physical fallback)
        "sofa.ms",       -- sofa assembly (6 types)
        "furniture.ms",  -- beds, chairs, tables, storage, decor, room sets
        "qa.ms",         -- automatic scene validation
        "ui.ms"          -- rollout / floater
    )

    local missing = #()

    for m in modules do
    (
        local path = moduleDir + m
        if doesFileExist path then
            fileIn path
        else
        (
            append missing m
            format "FurnGen ERROR: module not found: %\n" path
        )
    )

    if missing.count == 0 then
    (
        -- Optional convenience: register a macro so the tool can be dragged
        -- onto a toolbar or bound to a hotkey. Never blocks startup.
        try
        (
            local loaderPath = getThisScriptFilename()
            local macroBody = "macroScript FurnGen_Open category:\"FurnGen\" " + \
                "buttonText:\"FurnGen\" tooltip:\"FurnGen - Procedural Furniture Generator\" " + \
                "( fileIn @\"" + loaderPath + "\" )"
            execute macroBody
        )
        catch ( format "FurnGen: macro registration skipped (%)\n" (getCurrentException()) )

        fgOpenUI()

        format "FurnGen % ready. Recommended System Units: Centimeters.\n" FurnGen_Version
    )
    else
    (
        messageBox ("FurnGen could not start: " + missing.count as string + \
            " module(s) missing.\n\nKeep the folder structure intact:\n" + \
            "src/FurnGen.ms + src/modules/*.ms") title:"FurnGen"
    )
)
