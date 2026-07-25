/*
    sofa.ms -- sofa assembly
    -----------------------
    Assembles a sofa from primitives. Coordinate system:
        X -- width  (centred on 0)
        Y -- depth  (front = -Y, backrest = +Y)
        Z -- height (floor = 0)
    All dimensions are in centimetres.

    Extending the system: a new furniture family gets its own assembly
    module that reuses core / geometry / materials / qa.

    Depends on: core.ms, geometry.ms, materials.ms
*/

-------------------------------------------------------------------
-- A single seating "run": base + backrest + cushions + piping.
-- origin is the centre of the run on the floor, rotZ rotates the section.
-------------------------------------------------------------------
fn fgBuildRun cfg runWidth runDepth origin rotZ parts prefix withLeftArm withRightArm fabricMtl pipingMtl =
(
    local innerW = runWidth - (if withLeftArm then cfg.armWidth else 0.0) \
                            - (if withRightArm then cfg.armWidth else 0.0)
    local innerXOff = ((if withLeftArm then cfg.armWidth else 0.0) \
                     - (if withRightArm then cfg.armWidth else 0.0)) / 2.0

    local backD = 18.0
    local cushH = cfg.cushionHeight
    local baseTop = cfg.seatHeight - cushH * 0.55   -- cushion sinks into the base
    local baseH = baseTop - cfg.legHeight
    local seatD = runDepth - backD - 4.0
    local seatCount = (amax 1 (ceil (innerW / 70.0))) as integer
    if cfg.sofaType != #corner and prefix == "Main" then seatCount = cfg.seats
    local sectionParts = #()

    -- BASE
    local base = fgSoftBlock innerW runDepth baseH (baseH * 0.18) cfg (prefix + "_Base") softness:0.2
    base.pos = [innerXOff, 0, cfg.legHeight]
    base.material = fabricMtl
    append sectionParts base

    -- BACKREST, tilted slightly backwards
    local backH = cfg.height - baseTop
    local backPanel = fgSoftBlock innerW backD backH (backD * 0.35) cfg (prefix + "_Back") softness:0.4
    backPanel.pos = [innerXOff, runDepth / 2.0 - backD / 2.0, baseTop]
    rotate backPanel (eulerangles -5.0 0 0)
    backPanel.material = fabricMtl
    append sectionParts backPanel

    -- ARMRESTS
    if withLeftArm then
    (
        local armL = fgArm cfg -1 (prefix + "_Arm_L")
        armL.pos = [-runWidth / 2.0 + cfg.armWidth / 2.0, 0, cfg.legHeight]
        armL.material = fabricMtl
        append sectionParts armL
    )
    if withRightArm then
    (
        local armR = fgArm cfg 1 (prefix + "_Arm_R")
        armR.pos = [runWidth / 2.0 - cfg.armWidth / 2.0, 0, cfg.legHeight]
        armR.material = fabricMtl
        append sectionParts armR
    )

    -- SEAT CUSHIONS AND PIPING
    local gap = 1.5
    local cushW = (innerW - gap * (seatCount - 1)) / seatCount
    local seatY = -backD / 2.0 - 2.0
    for i = 1 to seatCount do
    (
        local cx = innerXOff - innerW / 2.0 + cushW / 2.0 + (i - 1) * (cushW + gap)
        local sc = fgCushion (cushW - 1.0) seatD cushH cfg (prefix + "_SeatCushion_" + i as string)
        sc.pos = [fgJitter cx 0.4, fgJitter seatY 0.5, baseTop]
        sc.material = fabricMtl
        append sectionParts sc

        if cfg.piping then
        (
            local pp = fgPiping (cushW - 1.0) seatD (cushH * 0.3) 0.7 (prefix + "_Piping_Seat_" + i as string)
            pp.pos = [sc.pos.x, sc.pos.y, baseTop + cushH * 0.62]
            pp.material = pipingMtl
            append sectionParts pp
        )

        -- BACK CUSHIONS, leaning against the backrest
        if cfg.backCushions then
        (
            local bcH = backH * 0.85
            local bc = fgCushion (cushW - 1.0) 12.0 bcH cfg (prefix + "_BackCushion_" + i as string) isBack:true
            -- Stand it up, then lean it on the backrest
            rotate bc (eulerangles (fgJitter -78.0 2.0) 0 0)
            bc.pos = [fgJitter cx 0.4, runDepth / 2.0 - backD - 5.0, baseTop + cushH * 0.5]
            bc.material = fabricMtl
            append sectionParts bc
        )
    )

    -- LEGS
    if cfg.legStyle != #none then
    (
        local inset = 8.0
        local legPos = #(
            [-runWidth / 2.0 + inset, -runDepth / 2.0 + inset, 0],
            [ runWidth / 2.0 - inset, -runDepth / 2.0 + inset, 0],
            [-runWidth / 2.0 + inset,  runDepth / 2.0 - inset, 0],
            [ runWidth / 2.0 - inset,  runDepth / 2.0 - inset, 0]
        )
        if runWidth > 200 then
        (
            append legPos [0, -runDepth / 2.0 + inset, 0]
            append legPos [0,  runDepth / 2.0 - inset, 0]
        )
        for i = 1 to legPos.count do
        (
            local lg = fgLeg cfg (prefix + "_Leg_" + i as string)
            lg.pos = legPos[i]
            append sectionParts lg
        )
    )

    -- Transform the whole section: rotate around the section's LOCAL origin.
    -- Multiplying transform by rotateZMatrix rotates both orientation and
    -- position around world zero, where the section was assembled. Then
    -- translate the result to origin.
    for p in sectionParts do
    (
        if rotZ != 0.0 then p.transform = p.transform * (rotateZMatrix rotZ)
        p.pos = p.pos + origin
        append parts p
    )
    sectionParts
)

-------------------------------------------------------------------
-- MAIN ENTRY POINT
-------------------------------------------------------------------
fn fgBuildSofa cfg =
(
    fgSetSeed cfg.seed
    local parts = #()

    local fabricMtl = fgMakeFabricMtl cfg
    local pipingMtl = fgMakePipingMtl cfg fabricMtl
    local legMtl = fgMakeLegMtl cfg

    -- Main run
    case cfg.sofaType of
    (
        #modular:
        (
            -- Modular sections with a visible gap; only the outer sections
            -- get an armrest. Gaps are subtracted from the section widths so
            -- the total width matches cfg.width exactly.
            local mGap = 2.0
            local secW = (cfg.width - cfg.armWidth * 2 - mGap * (cfg.seats - 1)) / cfg.seats
            for i = 1 to cfg.seats do
            (
                local isFirst = (i == 1)
                local isLast = (i == cfg.seats)
                local w = secW + (if isFirst then cfg.armWidth else 0) + (if isLast then cfg.armWidth else 0)
                local xStart = -cfg.width / 2.0 + (if isFirst then 0.0 else (cfg.armWidth + (secW + mGap) * (i - 1)))
                fgBuildRun cfg w cfg.depth [xStart + w / 2.0, 0, 0] 0.0 parts \
                    ("Module_" + i as string) isFirst isLast fabricMtl pipingMtl
            )
        )
        #corner:
        (
            -- Main run without a left armrest, plus a perpendicular section
            fgBuildRun cfg cfg.width cfg.depth [0, 0, 0] 0.0 parts "Main" false true fabricMtl pipingMtl
            local extLen = cfg.depth * 1.6
            fgBuildRun cfg extLen cfg.depth \
                [-cfg.width / 2.0 + cfg.depth / 2.0, -cfg.depth / 2.0 - extLen / 2.0 + cfg.depth, 0] \
                90.0 parts "Corner" true false fabricMtl pipingMtl
        )
        #chaise:
        (
            fgBuildRun cfg cfg.width cfg.depth [0, 0, 0] 0.0 parts "Main" true true fabricMtl pipingMtl
            -- Ottoman in front of the left seat
            local chW = (cfg.width - cfg.armWidth * 2) / cfg.seats
            local chD = cfg.depth * 0.7
            local chX = -cfg.width / 2.0 + cfg.armWidth + chW / 2.0
            local baseTop = cfg.seatHeight - cfg.cushionHeight * 0.55
            local chBase = fgSoftBlock chW chD (baseTop - cfg.legHeight) 4.0 cfg "Chaise_Base" softness:0.2
            chBase.pos = [chX, -cfg.depth / 2.0 - chD / 2.0 + 1.0, cfg.legHeight]
            chBase.material = fabricMtl
            append parts chBase
            local chCush = fgCushion (chW - 1.0) (chD - 2.0) cfg.cushionHeight cfg "Chaise_Cushion"
            chCush.pos = [chX, chBase.pos.y, baseTop]
            chCush.material = fabricMtl
            append parts chCush
            if cfg.legStyle != #none then for i = 1 to 2 do
            (
                local lg = fgLeg cfg ("Chaise_Leg_" + i as string)
                lg.pos = [chX + (if i == 1 then -1 else 1) * (chW / 2.0 - 8.0), chBase.pos.y - chD / 2.0 + 8.0, 0]
                append parts lg
            )
        )
        default:
        (
            -- straight / loveseat / armchair
            fgBuildRun cfg cfg.width cfg.depth [0, 0, 0] 0.0 parts "Main" true true fabricMtl pipingMtl
        )
    )

    -- STYLING: a throw over the armrest plus accent pillows
    if cfg.sofaDecor and cfg.sofaType != #modular then
    (
        local baseTop = cfg.seatHeight - cfg.cushionHeight * 0.55
        -- Throw blanket draped over the right armrest
        local thCol = fgPick #(color 190 170 140, color 150 120 95, color 200 195 185, \
            color (cfg.fabricColor.r * 0.6) (cfg.fabricColor.g * 0.6) (cfg.fabricColor.b * 0.6))
        local throwMtl = fgMakeBeddingMtl thCol mtlName:"FurnGen_Throw"
        local th = ChamferBox width:(cfg.armWidth + 14.0) length:(cfg.depth * 0.55) \
            height:3.0 fillet:1.2 name:"Sofa_Throw"
        fgSetChamferSegs th 10 3 2
        addModifier th (Bend BendAxis:0 BendAngle:150.0)
        addModifier th (Noisemodifier scale:12.0 fractal:true strength:[1.2, 1.2, 2.0] seed:(fgRandI 1 99999))
        addModifier th (TurboSmooth iterations:2)
        addModifier th (Uvwmap maptype:4 width:50 length:50 height:50)
        th.pos = [cfg.width / 2.0 - cfg.armWidth / 2.0, -6.0, cfg.armHeight + cfg.legHeight + 4.0]
        th.material = throwMtl
        append parts th
        -- Two accent pillows in the corners, tilted off-axis. The material
        -- goes through the verified factory rather than a silent copy recolor.
        local acCol = fgPick #(color 170 120 60, color 96 118 108, color 44 48 74, color 140 60 50)
        local acPrm = fgFabricParams cfg.fabric
        local acMtl = fgMakePBR acCol acPrm[1] (uniquename "FurnGen_AccentPillow") sheenAmt:acPrm[2] \
            bumpTex:(fgFabricBumpMap cfg.fabric acPrm) bumpAmt:acPrm[4]
        for i = 1 to 2 do
        (
            local px = (if i == 1 then -1 else 1) * (cfg.width / 2.0 - cfg.armWidth - 22.0)
            local ap = fgCushion 38.0 38.0 11.0 cfg (uniquename "Sofa_AccentPillow") isBack:true
            rotate ap (eulerangles (fgJitter -72.0 4.0) 0 (fgJitter 0.0 14.0))
            ap.pos = [fgJitter px 3.0, cfg.depth / 2.0 - 24.0, baseTop + cfg.cushionHeight + 6.0]
            ap.material = acMtl
            append parts ap
        )
    )

    -- Leg materials and scene layer, including child nodes such as the
    -- bolster of a #pillow armrest
    local sofaLayer = fgGetLayer "FurnGen_Furniture"
    for p in parts do
    (
        if matchPattern p.name pattern:"*_Leg_*" then p.material = legMtl
        if p.material == undefined then p.material = fabricMtl
        -- Drive wirecolor from the material so colour reads in Object Color mode
        p.wirecolor = fgMtlColor p.material (color 150 150 150)
        sofaLayer.addNode p
        for ch in p.children do
        (
            if ch.material == undefined then ch.material = p.material
            ch.wirecolor = fgMtlColor ch.material (color 150 150 150)
            sofaLayer.addNode ch
        )
    )

    -- Group under a unique name
    local grpName = uniquename ("Sofa_" + (cfg.style as string) + "_" + (cfg.sofaType as string))
    local grp = group parts name:grpName
    sofaLayer.addNode grp

    format "FurnGen: built '%' (% parts, seed %)\n" grpName parts.count cfg.seed
    grp
)
