/*
    geometry.ms -- soft-body primitives
    ----------------------------------
    Builders for the parts every item is made of: soft blocks, cushions,
    armrests, legs and piping seams.

    Realism pipeline:
        ChamferBox     -- base shape with a generous fillet
        -> Push        -- inflates along normals, mimicking the filling
        -> Noise       -- fractal folds and fabric irregularities
        -> TurboSmooth -- subdivision for soft silhouettes

    Uniqueness per generation comes from seeded jitter applied to positions,
    dimensions and to the seed of every Noise modifier.

    Depends on: core.ms
*/

-------------------------------------------------------------------
-- Quality preset -> #(segs, filletSegs, heightSegs, turboSmoothIterations)
-------------------------------------------------------------------
fn fgQualitySegs quality =
(
    case quality of
    (
        1: #(3, 2, 2, 1)   -- segs, filletSegs, hSegs, turboIters
        2: #(5, 3, 2, 2)
        3: #(8, 4, 3, 3)
        default: #(5, 3, 2, 2)
    )
)

-------------------------------------------------------------------
-- ChamferBox segment properties were renamed across Max versions,
-- so every candidate name is tried until one sticks.
-------------------------------------------------------------------
fn fgSetChamferSegs cb segs fsegs hsegs =
(
    fgSetFirst cb #(#lsegs, #Length_Segments, #lengthsegs) segs
    fgSetFirst cb #(#wsegs, #Width_Segments, #widthsegs) segs
    fgSetFirst cb #(#hsegs, #Height_Segments, #heightsegs) hsegs
    fgSetFirst cb #(#fsegs, #Fillet_Segments, #filletsegs) fsegs
)

-------------------------------------------------------------------
-- Soft block: frame, backrest, base. Rounded and lightly smoothed.
-------------------------------------------------------------------
fn fgSoftBlock w d h fillet cfg partName softness:0.25 =
(
    local q = fgQualitySegs cfg.quality
    -- Guard: a fillet larger than ~45% of the smallest dimension makes
    -- ChamferBox produce torn, self-intersecting geometry.
    local maxFillet = (amin (amin w d) h) * 0.45
    if fillet > maxFillet then fillet = maxFillet
    local b = ChamferBox width:w length:d height:h fillet:fillet name:partName
    fgSetChamferSegs b q[1] q[2] q[3]

    -- Slight inflation plus micro-noise removes the plastic CG look
    if softness > 0.01 then
    (
        addModifier b (Push Push_Value:(h * 0.02 * softness))
        addModifier b (Noisemodifier scale:(h * 1.2) fractal:true \
            strength:[w * 0.006 * softness, d * 0.006 * softness, h * 0.012 * softness] \
            seed:(fgRandI 1 99999))
    )
    addModifier b (TurboSmooth iterations:q[4])
    addModifier b (Uvwmap maptype:4 width:60 length:60 height:60)
    b
)

-------------------------------------------------------------------
-- Seat / back cushion: the single most important soft detail
-------------------------------------------------------------------
fn fgCushion w d h cfg partName isBack:false =
(
    local q = fgQualitySegs cfg.quality
    local soft = cfg.cushionSoftness
    local fillet = h * (0.26 + soft * 0.10)
    -- Same fillet guard as fgSoftBlock
    local maxFillet = (amin (amin w d) h) * 0.45
    if fillet > maxFillet then fillet = maxFillet

    local c = ChamferBox width:w length:d height:h fillet:fillet name:partName
    fgSetChamferSegs c (q[1] + 2) q[2] q[3]

    -- 1. Inflation: the filling pushing against the cover
    addModifier c (Push Push_Value:(h * (0.05 + soft * 0.07)))

    -- 2. Large folds: natural fabric sag
    addModifier c (Noisemodifier scale:(h * 1.4) fractal:true \
        strength:[w * 0.010 * soft, d * 0.014 * soft, h * 0.05 * soft] \
        seed:(fgRandI 1 99999))

    -- 3. Fine wrinkles (production and close-up quality only)
    if cfg.quality >= 2 then
        addModifier c (Noisemodifier scale:(h * 0.35) fractal:true \
            strength:[h * 0.008 * soft, h * 0.008 * soft, h * 0.015 * soft] \
            seed:(fgRandI 1 99999))

    -- 4. Subdivision
    addModifier c (TurboSmooth iterations:q[4])
    addModifier c (Uvwmap maptype:4 width:50 length:50 height:50)

    -- Organic imperfection: every cushion is tilted a little
    rotate c (eulerangles (fgJitter 0.0 0.7) (fgJitter 0.0 0.7) (fgJitter 0.0 1.0))
    c
)

-------------------------------------------------------------------
-- Piping: a renderable spline following the cushion perimeter
-------------------------------------------------------------------
fn fgPiping w d cornerR pipeR partName =
(
    local r = Rectangle width:(w * 0.985) length:(d * 0.985) cornerRadius:cornerR name:partName
    -- Renderable spline properties were also renamed between versions
    fgSetFirst r #(#render_renderable, #renderable) true
    fgSetFirst r #(#render_displayRenderMesh, #displayRenderMesh) true
    fgSetFirst r #(#render_thickness, #thickness) (pipeR * 2)
    fgSetFirst r #(#render_sides, #sides) 12
    r
)

-------------------------------------------------------------------
-- Armrest: three silhouettes
-------------------------------------------------------------------
fn fgArm cfg sideSign partName =
(
    -- sideSign: -1 = left, +1 = right
    local w = cfg.armWidth
    local d = cfg.depth
    local h = cfg.armHeight - cfg.legHeight
    local arm

    case cfg.armStyle of
    (
        #rounded:
        (
            arm = fgSoftBlock w d h (w * 0.42) cfg partName softness:0.5
        )
        #square:
        (
            arm = fgSoftBlock w d h (w * 0.14) cfg partName softness:0.2
        )
        #pillow:
        (
            -- Low frame plus a soft bolster on top (mid-century look)
            arm = fgSoftBlock w d (h * 0.7) (w * 0.15) cfg partName softness:0.25
            local roll = fgCushion (w * 1.1) d (h * 0.42) cfg (partName + "_Roll")
            roll.pos = [0, 0, h * 0.66]
            roll.parent = arm
        )
        default: ( arm = fgSoftBlock w d h (w * 0.3) cfg partName softness:0.3 )
    )
    arm
)

-------------------------------------------------------------------
-- Leg
-------------------------------------------------------------------
fn fgLeg cfg partName =
(
    local h = cfg.legHeight
    local leg
    case cfg.legStyle of
    (
        #cylinder: ( leg = Cylinder radius:2.2 height:h sides:18 name:partName )
        #cone:     ( leg = Cone radius1:2.8 radius2:1.3 height:h sides:18 name:partName )
        #block:    ( leg = Box width:6 length:6 height:h name:partName )
        #none:     ( leg = Box width:8 length:8 height:(amax h 1.5) name:partName )
        default:   ( leg = Cylinder radius:2.2 height:h sides:18 name:partName )
    )
    leg
)
